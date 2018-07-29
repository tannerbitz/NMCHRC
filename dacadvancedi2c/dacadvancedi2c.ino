#include <i2c_t3.h>
IntervalTimer myTimer;
int deviceAddress = 0x28;
volatile int data[8],sum=0;
#include "SdFat.h"
#define FILENAME_LENGTH 19
char fname[FILENAME_LENGTH];
String sdata;
long long int freq=1000;
int maxchannels=6;
int stream=1;
SdFatSdio sd;
// 8 MiB file.
int numfile=1;
int i2c_flag=0;
int record=0;
SdFatSdioEX sdEx;
volatile char a,b;
int filenum=1;
File file;
bool useEx = true;


void errorHalt(const char* msg){
  if (useEx){
    sdEx.errorHalt(msg);
  }
}


void runTest(char fname1[],String buf,int nb){
  char fin[nb];
  buf.toCharArray(fin,nb);
  file.println(buf);
}

void writetosd(){
  for (int c=0;c<=7;c++){
    if (c < 7){
      sdata=sdata+data[c]+',';
    }
    else{
      sdata=sdata+data[c];
    }
  }
  int strLength = sdata.length();
  if(stream==1){
    Serial.println(sdata);
  }
  if(a=='Q'){
    file.close();
    if(record==1)
    record=0;
  }

  if(a=='S' && record==0){
    Serial.println("ENTER FILENAME");
    while(!Serial.available()){
    }

    Serial.readBytes(fname,FILENAME_LENGTH);
    Serial.println(fname);
    Serial.println("Data acquisition Start");
    i2c_flag=1;
    // Wire.setDefaultTimeout(500); // 0.20
    // Setup for Master mode, pins 18/19, external pullups, 400kHz, 200ms default timeout

    useEx = true;
    if (!sdEx.begin()){
      sd.initErrorHalt("SdFatSdioEX begin() failed");
    }
    else{
      Serial.println("started");
    }

    sdEx.chvol();
    if (!file.open(fname, O_WRITE | O_CREAT|O_AT_END)){
      errorHalt("open failed");
    }

    record=1;
  }

  if(a=='S' && record==1){
    runTest(fname,sdata, strLength);
  }
  sdata="";
}



//-----------------------------------------------------------------------------
void setup() {
  char tname[9];
  char p;
  Serial.begin(115200);
  while (!Serial){
  }

  Serial.println("NMCHR LAB DAQ");


  if(p!='S'){
    while(!Serial.available()){
    }
    p=Serial.read();
  }

  Serial.println("ENTER FILENAME");
  while(!Serial.available()){
  }

  Serial.readBytes(fname,FILENAME_LENGTH);
  Serial.println(fname);
  Serial.println("Data acquisition Start");
  i2c_flag=1;
  // Wire.setDefaultTimeout(500); // 0.20
  // Setup for Master mode, pins 18/19, external pullups, 400kHz, 200ms default timeout

  useEx = true;
  if (!sdEx.begin()) {
    sd.initErrorHalt("SdFatSdioEX begin() failed");
  }
  else{
    Serial.println("started");
  }

  sdEx.chvol();
  if (!file.open(fname, O_WRITE | O_CREAT|O_AT_END)) {
    errorHalt("open failed");
  }
  record=1;
  a ='S';
  delay(1000);
  Wire.begin(I2C_MASTER, 0x00, I2C_PINS_18_19, I2C_PULLUP_EXT, 400000);
  Wire.setDefaultTimeout(200000); // 200ms
  myTimer.begin(writetosd,(int)((1000000)/freq));
}

//-----------------------------------------------------------------------------
void loop() {

  if(Serial.available())
  {
    a=Serial.read();
    b=a;
    if(b=='S'){
      i2c_flag=0;
      b=0;
    }
  }

  if(i2c_flag==1){
    int i = 0, ch = 0,c;
    i=sum%maxchannels;
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
    for (int c = 0; c < 2; c++){
      if (Wire.available()) result = result * 256 + ((Wire.read()));
    }
    //delay(500);
    result=result/16;
    if(result>2047){
      result=result-4096;
    }

    data[i] = result;
  }
}
