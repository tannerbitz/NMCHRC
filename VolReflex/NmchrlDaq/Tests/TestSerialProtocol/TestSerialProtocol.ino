#include <SimpleTimer.h>
#include <math.h>

// Init Timer
SimpleTimer timer;

enum Commands{
  START_WRITE = 0,
  STOP_WRITE = 1,
  PRINT_DAQ_READINGS = 2,
  PRINT_I2C_DEVICE_SETTINGS = 3,
  CUSTOMIZE_I2C_DEVICE = 4,
  CHANGE_VOLTAGE_RANGE = 5,
  INSERT_DAQ_READING = 6
};

enum VoltageRange{
  ZERO_TO_POS_FIVE = 0,
  NEG_FIVE_TO_POS_FIVE = 1,
  ZERO_TO_POS_TEN = 2,
  NEG_TEN_TO_POS_TEN = 3,
  NOT_APPLICABLE = 4
};


struct I2CDevice{
  uint8_t deviceAddress;
  uint8_t controlByte;
  VoltageRange voltageRange;
  bool useControlByte;
};

// Global Data
char serInput;
String serFullLine;
bool serReading = false;
bool serDoneReading = false;
long count = 0;
const uint8_t controlByteStartbit = 128;
int daqReadings[8] = {0, 0, 0, 0, 0 ,0 ,0, 0};
I2CDevice i2cDevs[8];

String getVoltageRangeStr(uint8_t voltageRange){
  String tempStr;
  switch (voltageRange) {
    case ZERO_TO_POS_FIVE:
      tempStr = "0V - +5V";
      break;
    case NEG_FIVE_TO_POS_FIVE:
      tempStr = "-5V - +5V";
      break;
    case ZERO_TO_POS_TEN:
      tempStr = "0V - +10V";
      break;
    case NEG_TEN_TO_POS_TEN:
      tempStr = "-10V - +10V";
      break;
    case NOT_APPLICABLE:
      tempStr = "Not applicable";
      break;
  }
  return tempStr;
}

void printI2CDeviceSettings(){
  String voltRangeStr;
  char i2cSettings[100];
  for (int i=0; i<8; i++){
    voltRangeStr = getVoltageRangeStr(i2cDevs[i].voltageRange);
    sprintf(i2cSettings,
            "<Channel: %i,DevAddr: %#x,CntrlByte: %i,UseCntrlByte: %s, VoltRng: %s>",
            i,
            i2cDevs[i].deviceAddress,
            i2cDevs[i].controlByte,
            (i2cDevs[i].useControlByte) ? "True" : "False",
            voltRangeStr.c_str());
    Serial.print(i2cSettings);
  }
}

void UpdateSineVal(){
  daqReadings[0] = (int) floor(sin(2*PI*count/100)*2047.99);
  count = (count + 1) % 1000;
}

uint8_t ResolveControlByte(uint8_t channel, uint8_t voltRange){
  /*
   * The DAQ127 uses the MAX127 chip.  The MAX127 chip is accessed by the Teensy3.6 using
   * an I2C connection.  To read from one of the eight channels on the DAQ127 one must
   * call the device address of the MAX127 chip (0x28) followed by a control byte.  This
   * control byte uses the form
   *
   *      startbit | sel2 | sel1 | sel0 | rng | bip | pd1 | pd0
   *
   *  - start bit is always 1  (therefore 128 because 2^7 = 128)
   *  - sel2, sel1, sel0 select the channel (0 - 7) ---> example: 1, 1, 1 == channel 7
   *  - rng and bip select the voltage range
   *      0, 0  = 0 ----->  0 to 5V
   *      0, 1  = 1 -----> -5 to 5V
   *      1, 0  = 2 ----->  0 to 10V
   *      1, 1  = 3 -----> -10 to 10V
   *   - pd1 and pd0 are always 0
   *
   *   The input "channel" must be between 0 and 7.  It is bitshifted 4 bits to make it the
   *   correct values for sel2, sel1, sel0
   *
   *   The input "voltRange" must be between 0 and 3.  It is bitshifted 2 bits to make it the
   *   correct values for rng and bip.
   */
  uint8_t controlByte = 0;
  if ( channel>=0 && channel<8  && voltRange>=0 && voltRange<4 ){
    uint8_t shiftedChannel = channel << 4;
    uint8_t shiftedVoltRange = voltRange << 2;
    controlByte = controlByteStartbit + shiftedChannel + shiftedVoltRange;
  }
  return controlByte;
}

void ResetDefaultI2CDevices(){
  /*
   * This function resets the i2cdevs array its default for all 8 channels.
   * The default voltage range is assumed to be -5 to 5V, thus defaultVoltageRange = 1
   * as detailed in the function explanation of the ResolveControlByte() function.
   */

  VoltageRange defaultVoltRange = NEG_FIVE_TO_POS_FIVE;
  for ( uint8_t channel=0; channel<8; channel++ ){
    i2cDevs[channel].deviceAddress = 0x28;
    i2cDevs[channel].controlByte = ResolveControlByte(channel, defaultVoltRange);
    i2cDevs[channel].voltageRange = defaultVoltRange;
    i2cDevs[channel].useControlByte = true;
  }
}

void printDaqReadings(){
  char daqReadingsStr[60];
  sprintf(daqReadingsStr,
          "<%i,%i,%i,%i,%i,%i,%i,%i>",
          daqReadings[0],
          daqReadings[1],
          daqReadings[2],
          daqReadings[3],
          daqReadings[4],
          daqReadings[5],
          daqReadings[6],
          daqReadings[7]);
  Serial.print(daqReadingsStr);
}


void insertDaqReading(String residualSerStr){
  char * residSerStr = residualSerStr.c_str();
  char * pch;
  pch = strtok(residSerStr, ",");
  while (pch != NULL){
    Serial.println(pch);
    pch = strtok(NULL, ",");
  }
}

bool isNumericString(String testStr){
  /*
   * This function checks if each character in passed string is 0-9,
   * a negative sign '-', or a period '.'
   */
  bool tempBool = true;
  char testChar;
  for (int i=0; i<testStr.length(); i++){
    testChar = testStr.charAt(i);
    if (isDigit(testChar)==0){
      if (!(testChar == '.' || testChar == '-')){
        tempBool = false;
        break;
      }
    }
  }
  return tempBool;
}

void changeVoltageRange(char * serLine){
  char * pch;
  pch = strtok(serLine, ", ");
  uint8_t inputCount = 0;
  int chan;
  int tempVoltRange;
  String tempStr;
  while (pch != NULL){
    inputCount++;
    if (inputCount == 1){ // Expecting Channel Number Input
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        chan = tempStr.toInt();
        // Ensure channel reading is between 0 and 7
        if ( chan < 0 || chan > 7 ){
          break;
        }
      }
      else{ // break out while loop if channel is not a number
        break;
      }
    }
    else if (inputCount == 2){ // Expecting Voltage Range Number Input
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        tempVoltRange = tempStr.toInt();
        if (tempVoltRange < 0 || tempVoltRange > 3){
          break;
        }
        else{
          i2cDevs[chan].controlByte = ResolveControlByte(chan, tempVoltRange);
          i2cDevs[chan].useControlByte = true;
          i2cDevs[chan].voltageRange = tempVoltRange;
        }
      }
      else{ // break if voltage range is not a number
        break;
      }
    }
    pch = strtok(NULL, ", ");
  }
}

void customizeI2CDeviceAddress(char * serLine){
int tempI2CDevAddr;
  char * pch;
  int chan;
  pch = strtok(serLine, ", ");
  uint8_t inputCount = 0;
  String tempStr;
  while (pch != NULL){
    inputCount++;
    if (inputCount == 1){ // Expecting Channel Number Input
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        chan = tempStr.toInt();
        // Ensure channel reading is between 0 and 7
        if ( chan < 0 || chan > 7 ){
          break;
        }
      }
      else{ // break out while loop if channel is not a number
        break;
      }
    }
    else if (inputCount == 2){ // Expecting I2C Device Address between 0-255
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        tempI2CDevAddr = tempStr.toInt();
        // Ensure I2C Device Address is between 0 and 255;
        if ( tempI2CDevAddr < 0 || tempI2CDevAddr > 255 ){
          break;
        }
        else{
          i2cDevs[chan].deviceAddress = tempI2CDevAddr;
          i2cDevs[chan].useControlByte = false;
          i2cDevs[chan].controlByte = 0;
          i2cDevs[chan].voltageRange = 4;
        }
      }
      else{ // break out while loop if channel is not a number
        break;
      }
    }
    pch = strtok(NULL, ", ");
  }
}

void insertDaqReading(char * serLine){
  /*
     * This reads the rest of the INSERT_DAQ_READING command.
     * It is expected that the command is of the form:
     *      <6,CHANNEL_NUMBER,VALUE_TO_WRITE>
     *
     * -6 is in the first position as it is the command number for INSERT_DAQ_READING
     * -CHANNEL_NUMBER and VALUE_TO_WRITE are integers
     * -CHANNEL_NUMBER must be between 0 and 7
     *
     * By this point, serLine should just be "CHANNEL_NUMBER,VALUE_TO_WRITE"
     */
  char * pch;
  pch = strtok(serLine, ", ");
  uint8_t inputCount = 0;
  int chan;
  String tempStr;
  while (pch != NULL){
    inputCount++;
    if (inputCount == 1){
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        chan = tempStr.toInt();
        // Ensure channel reading is between 0 and 7
        if ( chan < 0 || chan > 7 ){
          break;
        }
      }
      else{ // break out while loop if channel is not a number
        break;
      }
    }
    else if (inputCount == 2){
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        daqReadings[chan] = tempStr.toInt();
      }
      else{
        break;
      }
    }
    pch = strtok(NULL, ", ");
  }
}



void ParseSerialInput(){
  /*
   * This strips the first character off of the serial input string.
   * This character should be a number that corresponds to a command.
   * The value of the character is compared with command numbers and
   * then the corresponding command is carried out in another function.
   */
  String commandStr = serFullLine.substring(0,1);
  uint8_t command = commandStr.toInt();
  serFullLine.remove(0,2);
  char * serLine = serFullLine.c_str();
  if ( command == START_WRITE ){
    Serial.println("Start Write Default");
  }
  else if ( command == STOP_WRITE ){
    Serial.println("Stop Write");
  }
  else if ( command == CHANGE_VOLTAGE_RANGE ){
    changeVoltageRange(serLine);
  }
  else if ( command == CUSTOMIZE_I2C_DEVICE ){
    customizeI2CDeviceAddress(serLine);
  }
  else if ( command == PRINT_DAQ_READINGS ){
    printDaqReadings();
  }
  else if ( command == PRINT_I2C_DEVICE_SETTINGS ){
    printI2CDeviceSettings();
  }
  else if ( command == INSERT_DAQ_READING ){
    insertDaqReading(serLine);
  }
}


void setup() {
  // put your setup code here, to run once:

  //Initalize ControlByte array
  ResetDefaultI2CDevices();

  Serial.begin(9600);
  timer.setInterval(10, UpdateSineVal);
}

void loop() {
  // put your main code here, to run repeatedly:
  timer.run();

  if ( Serial.available() )
  {
    serInput = Serial.read();
    if ( serInput == '<' ) {
      serReading = true;
    }
    else if ( serInput == '>'){
      serReading = false;
      serDoneReading = true;
    }
    else if ( serReading ){
      serFullLine += serInput;
    }
  }
  if ( serDoneReading ){
    ParseSerialInput();
    serFullLine = "";
    serDoneReading = false;
  }

}
