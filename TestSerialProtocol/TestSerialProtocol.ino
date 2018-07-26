#include <SimpleTimer.h>
#include <math.h>

// Init Timer
SimpleTimer timer;

// Global Data
char serInput;
String serFullLine;
bool serReading = false;
bool serDoneReading = false;
long count = 0;
const uint8_t controlByteStartbit = 128;
int daqReadings[8] = {0, 0, 0, 0, 0 ,0 ,0, 0};

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
  ZERO_TO_POS_FIVE = 1,
  NEG_FIVE_TO_POS_FIVE = 2,
  ZERO_TO_POS_TEN = 3,
  NEG_TEN_TO_POS_TEN = 4
};


struct I2CDevice{
  uint8_t deviceAddress;
  uint8_t controlByte;
  VoltageRange voltageRange;
  bool useControlByte;
};

I2CDevice i2cDevs[8];


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

// Broken!!!!
void insertDaqReading(String residualSerStr){
  Serial.println(residualSerStr);
  String tempStr;
  int commaIndex = residualSerStr.indexOf(",");
  Serial.println(commaIndex);
  while ( commaIndex != -1 ){
    tempStr = residualSerStr.substring(0, commaIndex-1);
    Serial.println(tempStr);
    residualSerStr.remove(0, commaIndex);
  }
  Serial.println(tempStr);
}


void ParseSerialInput(){
  String commandStr = serFullLine.substring(0,1);
  uint8_t command = commandStr.toInt();
  serFullLine.remove(0,2);
  if ( command == START_WRITE ){
    Serial.println("Start Write Default");
  }
  else if ( command == STOP_WRITE ){
    Serial.println("Stop Write");
  }
  else if ( command == CHANGE_VOLTAGE_RANGE ){
    Serial.println("Change DAQ127 Channel Voltage Range");
  }
  else if ( command == CUSTOMIZE_I2C_DEVICE ){
    Serial.println("Custom I2C Device");
  }
  else if ( command == PRINT_DAQ_READINGS ){
    printDaqReadings();
  }
  else if ( command == PRINT_I2C_DEVICE_SETTINGS ){
    printI2CDeviceSettings();
  }
  else if ( command == INSERT_DAQ_READING ){
    insertDaqReading(serFullLine);
  }
}

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
