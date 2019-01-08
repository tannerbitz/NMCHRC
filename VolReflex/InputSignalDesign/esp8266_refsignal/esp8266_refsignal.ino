#include<Ticker.h>
#include<ESP8266WiFi.h>
#include<ESP8266WebServer.h>
#include<math.h>
#include<Wire.h>

ESP8266WebServer server;
Ticker timer;

// Network Info
char* ssid = "BetterLateThanNever";
char* password = "PleaseWork";
IPAddress ip(192, 168, 0, 107); //set static ip
IPAddress gateway(192, 168, 0, 1); //set getteway
IPAddress subnet(255, 255, 255, 0);//set subnet

// Global Data
const uint8_t MCP4725_ADDR = 0x60;
volatile int volt_write = 0;

float sinefreq = 1;
float sec2millis = 1000;
float millis2sec = 0.001;
float count = 0;
float cycleend_writecount = round(1/sinefreq*sec2millis);
bool dacwriteflag = false;
float step_t_length = 3.0;  //length of time step is on (in seconds)
float step_writecount = round(step_t_length*sec2millis);      //number of times StepSignal will be called before it detaches the timer


void UnidirectionFlex(){
  count++;
  volt_write = floor(2048 - 2047.1*cos(2.0*PI*sinefreq*millis2sec*count));

  if (count > cycleend_writecount){
    timer.detach();
    count = 0;
    dacwriteflag = false;
  }
}


void MultidirectionFlex(){
  count++;
  volt_write = floor(2048 + (2047.1*sin(2.0*PI*sinefreq*millis2sec*count)));

  if (count > cycleend_writecount){
    timer.detach();
    count = 0;
    dacwriteflag = false;
  }
}

void StepSignal(){
  count++;
  volt_write = 4095;

  if (count > step_writecount){
    timer.detach();
    count = 0;
    dacwriteflag = false;
  }
}

void CalibrationSignal(){
  count++;

  if (count < 500){
    volt_write = 0;
  }
  else if (count >=500 && count < 1000){
    volt_write = 4095;
  }
  else{
    timer.detach();
    count = 0;
    dacwriteflag = false;
  }
}

void ChangeStepTime(){
  String step_t_length_str = server.arg("T");
  step_t_length = step_t_length_str.toFloat();
  step_writecount = round(step_t_length*sec2millis);
  server.send(200, "");
}


// Parse url for freq
void ChangeFreq(){
  String sinefreqstr = server.arg("Freq");
  sinefreq = sinefreqstr.toFloat();
  cycleend_writecount = round(1/sinefreq*sec2millis);
  server.send(200, "");
}

void NewCycleUni()
{
  count = 0;
  timer.attach_ms(1, UnidirectionFlex);
  dacwriteflag = true;
  server.send(200, "");
}


void NewCycleMulti()
{
  count = 0;
  timer.attach_ms(1, MultidirectionFlex);
  dacwriteflag = true;
  server.send(200, "");
}

void NewCycleStep()
{
  count = 0;
  timer.attach_ms(1, StepSignal);
  dacwriteflag = true;
  server.send(200, "");
}




void Calibrate()
{
  count = 0;
  timer.attach_ms(1, CalibrationSignal);
  dacwriteflag = true;
  server.send(200, "");
}

void setup(){

  Wire.begin();

  // Wifi Setup
  WiFi.config(ip, gateway, subnet);
  WiFi.begin(ssid, password);
  WiFi.hostname("RefSignalGenerator");
  Serial.begin(115200);
  while(WiFi.status()!=WL_CONNECTED){
    Serial.print(".");
    delay(500);
  }
  Serial.println("");
  Serial.print("IP Address: ");
  Serial.print(WiFi.localIP());
  server.on("/ChangeFreq", ChangeFreq);
  server.on("/NewCycleUni", NewCycleUni);
  server.on("/NewCycleMulti", NewCycleMulti);
  server.on("/NewCycleStep", NewCycleStep);
  server.on("/ChangeStepTime", ChangeStepTime);
  server.on("/Calibrate", Calibrate);
  server.begin();

}

void loop(){
  server.handleClient();

  if (dacwriteflag){
    Wire.beginTransmission(MCP4725_ADDR);
    Wire.write(0x40);
    Wire.write(volt_write >> 4);
    Wire.write((volt_write & 15) << 4);
    Wire.endTransmission();
  }
  else{
    Wire.beginTransmission(MCP4725_ADDR);
    Wire.write(0x40);
    Wire.write(0 >> 4);
    Wire.write((0 & 15) << 4);
    Wire.endTransmission();
  }
}
