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
uint8_t controlByte[8];
const uint8_t controlByteStartbit = 128;

void ResolveControlByte(uint8_t channel, uint8_t voltRange){
  if ( channel<8 && voltRange<4 ){
    uint8_t shiftedChannel = channel << 4;
    uint8_t shiftedVoltRange = voltRange << 2;
    controlByte[channel] = controlByteStartbit + shiftedChannel + shiftedVoltRange;
  }
}

void ResetControlByteDefault(){
  uint8_t defaultVoltRange = 1;
  for ( uint8_t channel=1; channel<8; channel++ ){
    ResolveControlByte(channel, defaultVoltRange);
  }
}

void PrintControlByteArray(){
  char controlByteString[41];
  sprintf(controlByteString,
          "<%#x,%#x,%#x,%#x,%#x,%#x,%#x,%#x>",
          controlByte[0],
          controlByte[1],
          controlByte[2],
          controlByte[3],
          controlByte[4],
          controlByte[5],
          controlByte[6],
          controlByte[7]);
  Serial.print(controlByteString);
}

void ParseSerialInput(){
  String mode = serFullLine.substring(0,5);
  if ( mode=="SWDEF" ){
    Serial.println("Start Write Default");
  }
  else if ( mode=="SWUSR" ){
    Serial.println("Start Write User-Defined");
  }
  else if ( mode=="STOPW" ){
    Serial.println("Stop Write");
  }
  else if ( mode=="PRINT" ){
    Serial.print("<");
    Serial.print(sineVal);
    Serial.print(">");
  }
  else if ( mode=="PRCBA" ){
    PrintControlByteArray();
  }
}


void UpdateSineVal(){
  sineVal = sin(2*PI*count/100);
  count = (count + 1) % 1000;
}

void setup() {
  // put your setup code here, to run once:
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
