// Libraries
#include <i2c_t3.h>     // I2C (Wire) library for Teensy
#include <SdFat.h>      // SdCard Interface Library


// Serial Commands
enum Commands{
  START_WRITE = 0,
  STOP_WRITE = 1,
  PRINT_DAQ_READINGS = 2,
  PRINT_I2C_DEVICE_SETTINGS = 3,
  CUSTOMIZE_I2C_DEVICE = 4,
  CHANGE_VOLTAGE_RANGE = 5,
  INSERT_DAQ_READING = 6
};

// DAQ127 Channel Voltage Ranges
enum VoltageRange{
  ZERO_TO_POS_FIVE = 0,
  NEG_FIVE_TO_POS_FIVE = 1,
  ZERO_TO_POS_TEN = 2,
  NEG_TEN_TO_POS_TEN = 3,
  NOT_APPLICABLE = 4
};

// Define struct for each I2C Device/DAQ127 channel
struct I2CDevice{
  uint8_t deviceAddress;
  uint8_t controlByte;
  VoltageRange voltageRange;
  bool useControlByte;
};

// Timer Object
IntervalTimer myTimer;
int freq = 1000;
uint32_t intervalInMicroseconds = 1000000/freq;

// Timestamp Data
uint16_t fileYear; 
uint8_t fileMonth; 
uint8_t fileDay;
uint8_t fileHour;
uint8_t fileMinute;
uint8_t fileSecond;

// SdCard/File Objects
SdFatSdio sd;
SdFatSdioEX sdEx;
File file;

// Pertinent File Writing Variables
char * fname; 
bool writeTimestampFlag = false;
int daqReadings[8] = {0, 0, 0, 0, 0, 0, 0,0};
char daqReadingsStr[80];
I2CDevice i2cDevs[8];

// Serial Input Variables
char serInput;
String serFullLine;
bool serReading = false;
bool serDoneReading = false;


// Methods
bool isNumericString(String testStr){
  /*
   * This function checks if each character in passed string is 0-9,
   * a negative sign '-', or a period '.'
   */
  bool tempBool = true;
  char testChar;
  for (uint8_t i=0; i<testStr.length(); i++){
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
  /*
   * Change a DAQ127 channel's voltage range.  This changes the data
   * in i2cDevs[channel] and recalculates the control byte.
   */
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
          switch (tempVoltRange){
            case 0:
              i2cDevs[chan].voltageRange = ZERO_TO_POS_FIVE;
              break;
            case 1:
              i2cDevs[chan].voltageRange = NEG_FIVE_TO_POS_FIVE;
              break;
            case 2:
              i2cDevs[chan].voltageRange = ZERO_TO_POS_TEN;
              break;
            case 3:
              i2cDevs[chan].voltageRange = NEG_TEN_TO_POS_TEN;
          }
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
  /*
   * Configure an external I2C Device to be read during the read cycle
   * This device will be expected to supply a 2 byte, 16 bit signed integer
   * each read cycle
   */
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
          i2cDevs[chan].voltageRange = NOT_APPLICABLE;
        }
      }
      else{ // break out while loop if channel is not a number
        break;
      }
    }
    pch = strtok(NULL, ", ");
  }
}


String getVoltageRangeStr(uint8_t voltageRange){
  /* 
   * Return human readable voltage range given the 
   * voltage range integer/voltageRange enum 
   */
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
  /*
   * Print all info in i2cDevs array. Useful for debugging/checking changes
   */
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
  uint8_t controlByteStartbit = 128;
  uint8_t controlByte = 0;
  if ( channel>=0 && channel<8  && voltRange>=0 && voltRange<4 ){
    uint8_t shiftedChannel = channel << 4;
    uint8_t shiftedVoltRange = (uint8_t) (voltRange) << 2;
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
  /*
   * Print Comma Delimited DAQ Readings to Serial
   */
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


void writeToSdCard(){
  // Create a comma delimited string and write to file
  sprintf(daqReadingsStr,
          "%d,%d,%d,%d,%d,%d,%d,%d",
          daqReadings[0],
          daqReadings[1],
          daqReadings[2],
          daqReadings[3],
          daqReadings[4],
          daqReadings[5],
          daqReadings[6],
          daqReadings[7]);
  file.println(daqReadingsStr);
}


void startSdWrite(char * serLine){
  /*
   * This function parses the rest of the serial line for:
   * - filename (with file extension)
   * - year (optional)
   * - month (optional)
   * - day (optional)
   * - hour (optional)
   * - minute (optional)
   * - second (optional)
   * 
   * It then connects with the sd card, creates the file, and 
   * if it has the time information, then it also creates the timestamps
   */
  writeTimestampFlag = false;
  char * pch;
  pch = strtok(serLine, ", ");
  String tempStr;
  uint8_t inputCount = 0;
  fname = pch;
  while (pch != NULL){
    inputCount++;
    if (inputCount == 1){ // expecting filename
      fname = pch;
    }
    else if (inputCount == 2){ // expecting year
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        uint16_t tempYear = tempStr.toInt();
        if (tempYear > 1979 && tempYear < 2107){ // year must be between 1979-2107 per timestamp standards
          fileYear = tempYear;
        }
        else{  // if integer is not in valid range ----> don't write timestamp
          writeTimestampFlag = false;
          break;
        }
      }
      else{   // if string is not numeric ---> don't write timestamp
        writeTimestampFlag = false;
        break;
      }
    }
    else if (inputCount == 3){ // expecting month
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        uint8_t tempMonth = tempStr.toInt();
        if (tempMonth > 0 && tempMonth < 13){ // month must be between 1-12 per timestamp standards
          fileMonth = tempMonth;
        }
        else{   // if integer is not in valid range ----> don't write timestamp
          writeTimestampFlag = false;
          break;
        }
      }
      else{     // if string is not numeric ---> don't write timestamp
        writeTimestampFlag = false;
        break;
      }
    }
    else if (inputCount == 4){ // expecting day
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        uint8_t tempDay = tempStr.toInt();
        if (tempDay > 0 && tempDay < 32){ // day must be between 1-31 per timestamp standards
          fileDay = tempDay;
        }
        else{   // if integer is not in valid range ----> don't write timestamp
          writeTimestampFlag = false;
          break;
        }
      }
      else{     // if string is not numeric ---> don't write timestamp
        writeTimestampFlag = false;
        break;
      }
    }
    else if (inputCount == 5){ // expecting hour
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        uint8_t tempHour = tempStr.toInt();
        if (tempHour > -1 && tempHour < 24){ // hour must be between 0-23 per timestamp standards
          fileHour = tempHour;
        }
        else{   // if integer is not in valid range ----> don't write timestamp
          writeTimestampFlag = false;
          break;
        }
      }
      else{     // if string is not numeric ---> don't write timestamp
        writeTimestampFlag = false;
        break;
      }
    }
    else if (inputCount == 6){ // expecting minute
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        uint16_t tempMinute = tempStr.toInt();
        if (tempMinute > -1 && tempMinute < 60){ // minute must be between 0-59 per timestamp standards
          fileMinute = tempMinute;
        }
        else{   // if integer is not in valid range ----> don't write timestamp
          writeTimestampFlag = false;
          break;
        }
      }
      else{     // if string is not numeric ---> don't write timestamp
        writeTimestampFlag = false;
        break;
      }
    }
    else if (inputCount == 7){ // expecting second
      if (isNumericString(String(pch))){
        tempStr = String(pch);
        uint16_t tempSecond = tempStr.toInt();
        if (tempSecond > -1 && tempSecond < 60){ // second must be between 0-59 per timestamp standards
          fileSecond = tempSecond;
          writeTimestampFlag = true;
        }
        else{   // if integer is not in valid range ----> don't write timestamp
          writeTimestampFlag = false;
          break;
        }
      }
      else{     // if string is not numeric ---> don't write timestamp
        writeTimestampFlag = false;
        break;
      }
    }
    pch = strtok(NULL, ", ");
  }

  // Setup the sd card
  if(!sdEx.begin()){
    Serial.print("<Something went wrong with sdEx.begin()>");
    return;
  }
  sdEx.chvol();
  
  // Create/write to the file
  if (!file.open(fname, O_WRITE|O_CREAT|O_AT_END)){
    Serial.print("<Something went wrong opening the file>");
    return;
  }
  
  // Change the 'Created' and 'Modified' and 'Accessed' timestamps of the file
  if (writeTimestampFlag){
    if (!file.timestamp(T_CREATE, fileYear, fileMonth, fileDay, fileHour, fileMinute, fileSecond)){
      Serial.print("<Something went wrong with the 'Modified' timestamp>");
    }
    if (!file.timestamp(T_WRITE, fileYear, fileMonth, fileDay, fileHour, fileMinute, fileSecond)){
      Serial.print("<Something went wrong with the 'Modified' timestamp>");
    }
    if (!file.timestamp(T_ACCESS, fileYear, fileMonth, fileDay, fileHour, fileMinute, fileSecond)){
      Serial.print("<Something went wrong with the 'Modified' timestamp>");
    }
  }

  // Start Timer To call writeToSdCar every 1ms
  myTimer.begin(writeToSdCard, intervalInMicroseconds);
}

void stopSdWrite(){
  // Stop Calling writeToSdCard and close file
  myTimer.end(); 
  file.close();
}

void ParseSerialInput(){
  /*
   * This strips the first character off of the serial input string.
   * This character should be a number that corresponds to a command.
   * The value of the character is compared with command numbers and
   * then the corresponding command is carried out in another function.
   */
  String commandStr = serFullLine.substring(0,1);
  uint8_t cmd = commandStr.toInt();
  serFullLine.remove(0,2);
  char * serLine = new char[serFullLine.length()+1];
  strcpy(serLine, serFullLine.c_str());
  if ( cmd == START_WRITE ){
    startSdWrite(serLine);
  }
  else if ( cmd == STOP_WRITE ){
    stopSdWrite();
  }
  else if ( cmd == CHANGE_VOLTAGE_RANGE ){
    changeVoltageRange(serLine);
  }
  else if ( cmd == CUSTOMIZE_I2C_DEVICE ){
    customizeI2CDeviceAddress(serLine);
  }
  else if ( cmd == PRINT_DAQ_READINGS ){
    printDaqReadings();
  }
  else if ( cmd == PRINT_I2C_DEVICE_SETTINGS ){
    printI2CDeviceSettings();
  }
  else if ( cmd == INSERT_DAQ_READING ){
    insertDaqReading(serLine);
  }
  delete serLine;
}



void setup() {

  //Initalize ControlByte array
  ResetDefaultI2CDevices();
  
  // Begin Serial
  Serial.begin(115200);

  // Begin I2C (Wire) Library
  Wire.begin(I2C_MASTER, 0x00, I2C_PINS_18_19, I2C_PULLUP_EXT, 400000);
  Wire.setDefaultTimeout(200000); // 200ms
  
}

void loop() {
  /* 
   * Check for new serial input. Append character to serFullLine is there is
   * a new character. Always start a new serFullLine with a '<' character and
   * end it with a '>' character. 
   */
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

  // Sample Data
  for (int chan=0; chan<6; chan++){
    Wire.beginTransmission(i2cDevs[chan].deviceAddress);
    if (i2cDevs[chan].useControlByte){ // This is true when reading from DAQ127 channels
      Wire.write(i2cDevs[chan].controlByte);
    }
    Wire.endTransmission();
    uint8_t bytesRequested = 2;
    Wire.requestFrom(i2cDevs[chan].deviceAddress, bytesRequested);
    uint16_t tempData = 0;
    for (int iByte=0; iByte<bytesRequested; iByte++){
      if (Wire.available()){
        tempData = (tempData << 8) + Wire.read();
      }
    }
    if (i2cDevs[chan].useControlByte){  // DAQ127 has 12 bit precision so need to discard 4 lsb's
      tempData = (tempData >> 4);
      if (tempData > 2047){             // Convert to signed int
        tempData = tempData - 4096;
      }
    }
    else{                               // Expected that a 16 bit integer is being sent
      if (tempData > 32767){            // Convert to signed int
        tempData = tempData - 65536;
      }
    }
    daqReadings[chan] = tempData;
  }
}
