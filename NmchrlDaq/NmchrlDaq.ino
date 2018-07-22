/*
 * Name:          NmchrlDaq.ino
 * Authors:       Varun Nalam, Tanner Bitz
 * Description:   This code runs on a Teensy 3.6 and performs the following functions:
 *                  - Reads data on channels 0-5 from the DAQ-127 board over I2C at 1000Hz
 *                  - Writes DAQ data to the serial port periodically (currently 100Hz)
 *                  - Writes DAQ data to SD card on Teensy at 1000Hz
 */

// Libraries
#include <i2c_t3.h>                   // i2c library
#include "SdFat.h"                    // sd card interface library

// Global Variables
IntervalTimer myTimer;                // Teensy 3.6 supported timer for interrupts
int deviceAddress = 0x28;             // DAQ-127 I2C Address
// uint8_t controlbyte[8];
// const uint8_t controlbyteStartbit = 128;

volatile int data[8];                 // temp data array for DAQ-127 Channel Readings
volatile int sum=0;
const int filenameLength = 19;        // Max length of char array holding filename info
char filename[filenameLength];        // char array to hold filename info

String sdata;
long long int freq=1000;
int maxChannels=6;                 //------------>  this will be an input
int stream=1;
SdFatSdio sd;                         // init sd card object

// 8 MiB file.
int i2c_flag=0;
int record=0;
SdFatSdioEX sdEx;

File file;
bool useEx = true;
//-----------------------------------------------------------------------------
bool sdBusy() {
}
//-----------------------------------------------------------------------------

void errorHalt(const char* msg) {
  if (useEx) {
    sdEx.errorHalt(msg);
  }
}
//------------------------------------------------------------------------------
uint32_t kHzSdClk() {
  return sdEx.card()->kHzSdClk();
}
//------------------------------------------------------------------------------
// Replace "weak" system yield() function.

void


//-----------------------------------------------------------------------------
void runTest(char filename1[],String buf,int nb)
{
  char fin[nb];
  buf.toCharArray(fin,nb);
  //      if (nb != file.write(fin, nb))
  //      {
  //        errorHalt("write failed");
  //      }
  //      else
  //      {
  //        Serial.println("written");
  //      }
  file.println(buf);

}


// Global data
volatile char a,b;
int filenum=1;




void writetosd()
{
  for (int c=0;c<=7;c++)
  {
    if (c < 7)
    {
      sdata=sdata+data[c]+',';
    }
    else
    {
      sdata=sdata+data[c];
    }
  }

  int strLength = sdata.length();
  if(stream==1)
    Serial.println(sdata);
  if(a=='Q')
  {
    file.close();
    if(record==1)
      record=0;
  }
  if(a=='S' && record==0)
  {
    Serial.println("ENTER FILENAME");
    while(!Serial.available())
    {

    }

    Serial.readBytes(filename,filenameLength);

    Serial.println(filename);
    Serial.println("Data acquisition Start");
    i2c_flag=1;
    //    Wire.setDefaultTimeout(500); // 0.20
    // Setup for Master mode, pins 18/19, external pullups, 400kHz, 200ms default timeout

    useEx = true;
    if (!sdEx.begin()) {
      sd.initErrorHalt("SdFatSdioEX begin() failed");
    }
    else{
      Serial.println("started");
    }

    sdEx.chvol();
    if (!file.open(filename, O_WRITE | O_CREAT|O_AT_END)) {
      errorHalt("open failed");
    }

    record=1;

  }






  if(a=='S' && record==1){
    runTest(filename,sdata, strLength);

  }
  sdata="";
}

//-----------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  // while (!Serial) {
  // }
  //
  // Serial.println("NMCHR LAB DAQ");
  //
  //
  // if(serInput!='S'){
  //   while(!Serial.available())
  //   {
  //
  //   }
  //   serInput=Serial.read();
  // }
  //
  // Serial.println("ENTER FILENAME");
  // while(!Serial.available())
  // {
  //
  // }
  // Serial.readBytes(filename,filenameLength);
  //
  // Serial.println(filename);
  // Serial.println("Data acquisition Start");
  // i2c_flag=1;
  // //    Wire.setDefaultTimeout(500); // 0.20
  // // Setup for Master mode, pins 18/19, external pullups, 400kHz, 200ms default timeout
  //
  // useEx = true;
  // if (!sdEx.begin()) {
  //   sd.initErrorHalt("SdFatSdioEX begin() failed");
  // }
  // // make sd the current volume
  // sdEx.chvol();
  //
  // if (!file.open(filename, O_WRITE | O_CREAT|O_AT_END)) {
  //   errorHalt("open failed");
  // }
  // record=1;
  // a='S';
  // delay(1000);

  // Setup I2C communication
  Wire.begin(I2C_MASTER, 0x00, I2C_PINS_18_19, I2C_PULLUP_EXT, 400000);
  Wire.setDefaultTimeout(200000); // 200ms

// initialize timer when start command received / stop timer when stop command received
  // // Initialize timer
  // myTimer.begin(writetosd,(int)((1000000)/freq));

}

char serInput;
String serFullLine;
bool serReading = false;


//-----------------------------------------------------------------------------
void loop() {

  if( Serial.available() )
  {
    do {
      serInput = Serial.read();
      if ( serInput=='>' ){
        serReading = true;
      else if ( serInput == '\n')
      }
    } while( Serial.available() ){

    }
    a=Serial.read();
    b=a;
    if(b=='S')
    {
      i2c_flag=0;
      b=0;
    }

  }
  if(i2c_flag==1)
  {
    int i = 0, ch = 0,c;
    i=sum%maxChannels;
    sum=sum+1;
    if (i==0){ // this changes the input from -5V to +5V ---------> 0V - +5V on channel zero.
      ch = 128;
    }
    else{
      ch=132+(16*i);
    }

    //    tim2=micros();
    Wire.beginTransmission(deviceAddress);
    Wire.write(ch);
    Wire.endTransmission();
    Wire.requestFrom(deviceAddress, 2);
    int result = 0;
    for (int c = 0; c < 2; c++)
      if (Wire.available()) result = result * 256 + ((Wire.read()));
    //delay(500);
    result=result/16;
    if(result>2047)
    {
      result=result-4096;
    }

    data[i] = result;

  }
}
