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
volatile int volt_write = 2048;

float sinefreq = 1;
float sec2millis = 1000;
float millis2sec = 0.001;
float count = 0;
float cycleend_writecount = round(1/sinefreq*sec2millis);
bool dacwriteflag = false;


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
}
