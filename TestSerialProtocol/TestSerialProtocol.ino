#include <SimpleTimer.h>

// Init Timer
SimpleTimer timer;

// Global Data
char serInput;
String serFullLine;
bool serReading = false;
bool serDoneReading = false;
long count = 0;
float sineVal;
const uint8_t controlByteStartbit = 128;

enum Commands{
  StartWrite = 0,
  StopWrite = 1,
  PrintDaqReadings = 2,
  PrintI2CDeviceSettings = 3,
  CustomizeI2CDevice = 4,
  ChangeDaqChannelVoltageRange = 5
};

enum VoltageRange{
  ZeroToPosFive = 1,
  NegFiveToPosFive = 2,
  ZeroToPosTen = 3,
  NegTenToPosTen = 4
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

  VoltageRange defaultVoltRange = NegFiveToPosFive;
  for ( uint8_t channel=0; channel<8; channel++ ){
    i2cDevs[channel].deviceAddress = 0x28;
    i2cDevs[channel].controlByte = ResolveControlByte(channel, defaultVoltRange);
    i2cDevs[channel].voltageRange = defaultVoltRange;
    i2cDevs[channel].useControlByte = true;
  }
}

// void PrintControlByteArray(){
//   char controlByteString[41];
//   sprintf(controlByteString,
//           "<%#x,%#x,%#x,%#x,%#x,%#x,%#x,%#x>",
//           controlByte[0],
//           controlByte[1],
//           controlByte[2],
//           controlByte[3],
//           controlByte[4],
//           controlByte[5],
//           controlByte[6],
//           controlByte[7]);
//   Serial.print(controlByteString);
// }




void ParseSerialInput(){
  String commandStr = serFullLine.substring(0,1);
  uint8_t command = commandStr.toInt();
  if ( command == StartWrite ){
    Serial.println("Start Write Default");
  }
  else if ( command == StopWrite ){
    Serial.println("Stop Write");
  }
  else if ( command == ChangeDaqChannelVoltageRange ){
    Serial.println("Change DAQ127 Channel Voltage Range");
  }
  else if ( command == CustomizeI2CDevice){
    Serial.println("Custom I2C Device");
  }
  else if ( command == PrintDaqReadings ){
    Serial.println("Print Daq Readings");
    // Serial.print("<");
    // Serial.print(sineVal);
    // Serial.print(">");
  }
  else if ( command == PrintI2CDeviceSettings ){
    Serial.println("Print I2C Device Settings");
    // PrintControlByteArray();
  }
}


void UpdateSineVal(){
  sineVal = sin(2*PI*count/100);
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
