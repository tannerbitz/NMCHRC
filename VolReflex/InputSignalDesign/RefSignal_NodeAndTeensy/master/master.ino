#include<ESP8266WiFi.h>
#include<ESP8266WebServer.h>
#include<math.h>
#include<Wire.h>

// Webserver 
ESP8266WebServer server;

//LED Toggle
bool ledmode = 0;

// Network Info
char* ssid = "BetterLateThanNever";
char* password = "PleaseWork";
IPAddress ip(192, 168, 0, 107); //set static ip
IPAddress gateway(192, 168, 0, 1); //set getteway
IPAddress subnet(255, 255, 255, 0);//set subnet

// Slave (Teensy) I2C Address
int i2cSlaveAdd = 15;

// Relay server argument to i2c string
void RelayToI2C(){
  String i2cCommand = server.arg("Command");
  i2cCommand = "<" + i2cCommand + ">";
  Serial.println(i2cCommand);
  ledmode = !(ledmode);
  digitalWrite(LED_BUILTIN, ledmode);
  server.send(200, "");
}

void Blink(){
  ledmode = !(ledmode);
  digitalWrite(LED_BUILTIN, ledmode);
  server.send(200, "");
}

void setup() {
  // Turn On Led
  pinMode(LED_BUILTIN, OUTPUT);
  
  // Start I2C Connection
  Wire.begin(D1, D2); // D5 = SDA, D6 = SCL

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
  server.on("/RelayToI2C", RelayToI2C);
  server.on("/Blink", Blink);
  server.begin();
}

void loop() {
  // put your main code here, to run repeatedly:
  server.handleClient();

}
