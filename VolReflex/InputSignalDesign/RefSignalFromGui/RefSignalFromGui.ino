#include<DueTimer.h>
#include <Wire.h>


// Gloabl Data
const uint8_t MCP4725_ADDR = 0x60;
float TsSine = 1000; // 1ms
volatile int volt_write =0;

float sinefreq = 1;
float sec2micros = 1000000;
float cycletime_micros = 1/sinefreq*sec2micros;
float cycletimestart_micros = 0;
float cycletimeend_micros = cycletimestart_micros + cycletime_micros;
float sine_write_t = 0;

float printfreq = 1000;
String serFullLine;
char serInput;
bool serReading = false;
bool serDoneReading = false;

enum Commands{
  NEW_CYCLE = 0,
  CHANGE_FREQ = 1
};

void ChangeFreq(char * serLine){
  sinefreq = atof(serLine);
  cycletime_micros = 1/sinefreq*sec2micros;
}


void NewCycle()
{
  cycletimestart_micros = micros();
  cycletimeend_micros = cycletimestart_micros + cycletime_micros;

  while ( micros() < cycletimeend_micros ){
    sine_write_t = (micros() - cycletimestart_micros)/sec2micros;
    volt_write = 2048 + floor(2047.99*sin(2*PI*sinefreq*sine_write_t));

    Wire.beginTransmission(MCP4725_ADDR);
    Wire.write(0x40);
    Wire.write(volt_write >> 4);
    Wire.write((volt_write & 15) << 4);
    Wire.endTransmission();

    delayMicroseconds(400);
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
  uint8_t cmd = commandStr.toInt();
  serFullLine.remove(0,2);
  char * serLine = new char[serFullLine.length()+1];
  strcpy(serLine, serFullLine.c_str());
  if ( cmd == NEW_CYCLE ){
    NewCycle();
  }
  else if ( cmd == CHANGE_FREQ ){
    ChangeFreq(serLine);
  }
  delete serLine;
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);

  Wire.begin();
//  Timer3.attachInterrupt(printsine);
//  Timer3.setFrequency(printfreq);
//  Timer3.start();
}

void loop() {
  // put your main code here, to run repeatedly:


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
