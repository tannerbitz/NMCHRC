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
