// Due Libraries
#include <DueTimer.h>
#include <Wire.h>

// Gloabl Data
const uint8_t MCP4725_ADDR = 0x60;
float TsSine = 1000; // 1ms
float TsPrbs = 250000; // 250ms
const uint8_t sineFreqListLength = 5;
uint8_t totalPossibleInputSignals = 6;
float sineFreqs[sineFreqListLength] = {0.25, 0.5, 1.0, 1.25, 1.5};

volatile int volt_write =0;


const int buttonpin = 13;     // the number of the pushbutton pin
const int ledsine1 =  4;      // the number of the LED pin
const int ledsine2 = 5;
const int ledsine3 = 6;
const int ledsine4 = 7;
const int ledsine5 = 8;
const int ledprbs = 9;
int counter = 0;

// PRBS Variables
uint8_t prbsval = 0x02;
uint8_t newbit;

// variables will change:
boolean buttonState = 0;         // variable for reading the pushbutton status
boolean prevButtonState = 0;



void writeSinusoid(){
  volt_write = 2048 + floor(2047.99*sin(2*PI*sineFreqs[counter]*micros()/1000000));
}

void writePrbs(){
  newbit = (((prbsval >> 4) ^ (prbsval >> 2)) & 1);
  prbsval = ((prbsval << 1) | newbit) & 0x1f;
  if (newbit == 0){
    volt_write = 0; 
  }
  else if (newbit == 1){
    volt_write = 4095;
  }
  else{ // something would be going very wrong here
    volt_write = 2048;
  }
}


boolean debounce(boolean last){
  boolean current = digitalRead(buttonpin);
  if (last != current){
    delay(125);
    current= digitalRead(buttonpin);
  }
  return current;
}

void changeLed(int cnt){
  if (cnt == 0){
    digitalWrite(ledsine1, HIGH);
    digitalWrite(ledsine2, LOW);
    digitalWrite(ledsine3, LOW);
    digitalWrite(ledsine4, LOW);
    digitalWrite(ledsine5, LOW);
    digitalWrite(ledprbs, LOW);
  }
  else if (cnt == 1){
    digitalWrite(ledsine1, LOW);
    digitalWrite(ledsine2, HIGH);
    digitalWrite(ledsine3, LOW);
    digitalWrite(ledsine4, LOW);
    digitalWrite(ledsine5, LOW);
    digitalWrite(ledprbs, LOW);
  }
  else if (cnt ==2){
    digitalWrite(ledsine1, LOW);
    digitalWrite(ledsine2, LOW);
    digitalWrite(ledsine3, HIGH);
    digitalWrite(ledsine4, LOW);
    digitalWrite(ledsine5, LOW);
    digitalWrite(ledprbs, LOW);
  }
  else if (cnt == 3){
    digitalWrite(ledsine1, LOW);
    digitalWrite(ledsine2, LOW);
    digitalWrite(ledsine3, LOW);
    digitalWrite(ledsine4, HIGH);
    digitalWrite(ledsine5, LOW);
    digitalWrite(ledprbs, LOW);
  }
  else if (cnt == 4){
    digitalWrite(ledsine1, LOW);
    digitalWrite(ledsine2, LOW);
    digitalWrite(ledsine3, LOW);
    digitalWrite(ledsine4, LOW);
    digitalWrite(ledsine5, HIGH);
    digitalWrite(ledprbs, LOW);
  }
  else if (cnt == 5){
    digitalWrite(ledsine1, LOW);
    digitalWrite(ledsine2, LOW);
    digitalWrite(ledsine3, LOW);
    digitalWrite(ledsine4, LOW);
    digitalWrite(ledsine5, LOW);
    digitalWrite(ledprbs, HIGH);
  }
  else{
    digitalWrite(ledsine1, LOW);
    digitalWrite(ledsine2, LOW);
    digitalWrite(ledsine3, LOW);
    digitalWrite(ledsine4, LOW);
    digitalWrite(ledsine5, LOW);
    digitalWrite(ledprbs, LOW);
  }
}

void setup()
{

  // initialize the LED pin as an output:
  pinMode(ledsine1, OUTPUT);
  pinMode(ledsine2, OUTPUT);
  pinMode(ledsine3, OUTPUT);
  pinMode(ledsine4, OUTPUT);
  pinMode(ledsine5, OUTPUT);
  pinMode(ledprbs, OUTPUT);
  // initialize the pushbutton pin as an input:
  pinMode(buttonpin, INPUT);

  // Setup I2C Connection for MCP4725 Device
  Wire.begin();

  //Setup interrupt
  Timer3.attachInterrupt(writeSinusoid);
  Timer3.setPeriod(TsSine);
  Timer3.start();

}

void loop()
{
  // Write to DAC
  Wire.beginTransmission(MCP4725_ADDR);
  Wire.write(0x40);
  Wire.write(volt_write >> 4);
  Wire.write((volt_write & 15) << 4);
  Wire.endTransmission();
  // read the state of the pushbutton value:
  
  buttonState = debounce(prevButtonState);

  // check if the pushbutton is pressed. If it is, the buttonState is HIGH:
  if (prevButtonState == LOW && buttonState == HIGH) {
    counter = (++counter % totalPossibleInputSignals);
    if (counter == 0) { // switch from PRBS to Sinsuoids
      Timer3.stop();
      Timer3.detachInterrupt();
      Timer3.attachInterrupt(writeSinusoid);
      Timer3.setPeriod(TsSine);
      Timer3.start();
    }
    else if (counter >= sineFreqListLength && counter <totalPossibleInputSignals){ // switch from sinusoids to PRBS
      Timer3.stop();
      Timer3.detachInterrupt();
      Timer3.attachInterrupt(writePrbs);
      Timer3.setPeriod(TsPrbs);
      Timer3.start();
    }
    changeLed(counter);
  }
}
