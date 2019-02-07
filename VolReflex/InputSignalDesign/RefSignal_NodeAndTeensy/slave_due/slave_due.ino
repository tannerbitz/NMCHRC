/*                                
 *                                 Description
 * 
 * This script serves at the software for the Teensy 3.2 that is running as 
 * the I2C slave device.  The GUI sends commands to the NodeMcu which are relayed
 * to the Teensy 3.2.  The Teensy 3.2 then interrepts the commands and executes them.
 * 
 * As of this writing, the main job of the Teensy 3.2 is to output a singular 
 * analog sine signal when requested.  It will use it's onboard DAC to do this task.  
 * The DAC on the Teensy 3.2 outputs a range of 0-3.3V, but the DAQ is setup to 
 * do a ADC of 0-5V. To meet this spec, we will boost the 0-3.3V to 0-5V with an op-amp
 */
#include <DueTimer.h>
#include <Wire.h>

// Global Data
const uint8_t MCP4725_ADDR = 0x60;

// For serial reading process
bool serReading = false;
bool serDoneReading = false;
char serInput;
String serCmd;

// Container to hold commands this gets from NodeMcu over I2C
char commandStr[50];

// voltWrite is the 12 bit integer value that is used for the DAC
volatile int voltWrite = 0;
int voltWriteFloor = 0;
int voltWriteCeil = 4095;

// Update Volt Write Range
int CalcVoltWriteRange(){
  return (voltWriteCeil - voltWriteFloor + 1);
}
int voltWriteRange = CalcVoltWriteRange();

// Initialize the sinusoid freqs/sampling
float sineFreq = 1;
float sec2millis = 1000;
float millis2sec = 0.001;
float count = 0;
bool duringCmdSig = false;
float cycleEndWriteCount; //initialized in setup

// Initialize the step signal
float stepTLength = 3.0;  //length of time step is on (in seconds)
float stepWriteCount; // initialized in setup


// Commands from I2C
enum Commands{
  ERROR_CMD = 0,
  UNIDIRECTION_FLEX = 1,
  MULTIDIRECTION_FLEX = 2,
  UNIDIRECTION_FLEX_WITH_BOUNDS = 3,
  STEP_SIGNAL = 4,
  CALIBRATION_SIGNAL = 5,
  CHANGE_FREQ = 6,
  CHANGE_STEP_DURATION = 7,
  CHANGE_VOLT_WRITE_FLOOR = 8,
  CHANGE_VOLT_WRITE_CEIL = 9
};


void UnidirectionFlex(){
  count++;
  duringCmdSig = true;
  voltWrite = min(4095, floor(voltWriteFloor + voltWriteRange/2*(1 -cos(2.0*PI*sineFreq*millis2sec*count))));

  if (count > cycleEndWriteCount){
    Timer3.detachInterrupt();;
    Timer3.stop();
    count = 0;
    duringCmdSig = false;
  }
}

void UnidirectionFlexWithBounds(){
  /*
   * This method will be the same as a UnidirectionFlex() but will have
   * 5ms of full voltage before and after
   */
  count++;
  duringCmdSig = true;
  if (count < 6)
  {
    voltWrite == voltWriteCeil;
  }
  else if (count >= 6 && count < cycleEndWriteCount + 6)
  {
    voltWrite = min(4095, floor(voltWriteFloor + voltWriteRange/2*(1 -cos(2.0*PI*sineFreq*millis2sec*count))));
  }
  else
  {
    voltWrite = voltWriteCeil;
    if (count > cycleEndWriteCount + 12)
    {
      Timer3.detachInterrupt();;
      Timer3.stop();
      count = 0;    
      duringCmdSig = false;
    }
  }
}

void MultidirectionFlex(){
  count++;
  duringCmdSig = true;
  voltWrite = min(4095, floor(voltWriteFloor + voltWriteRange/2*(1 + sin(2.0*PI*sineFreq*millis2sec*count))));

  if (count > cycleEndWriteCount){
    Timer3.detachInterrupt();;
    Timer3.stop();
    count = 0;
    duringCmdSig = false;
  }
}

void StepSignal(){
  count++;
  duringCmdSig = true;
  voltWrite = voltWriteCeil;

  if (count > stepWriteCount){
    Timer3.detachInterrupt();;
    Timer3.stop();
    count = 0;
    duringCmdSig = false;
  }
}

void CalibrationSignal(){
  count++;
  duringCmdSig = true;

  if (count < 500){
    voltWrite = voltWriteFloor;
  }
  else if (count >=500 && count < 1000){
    voltWrite = voltWriteCeil;
  }
  else{
    Timer3.detachInterrupt();;
    Timer3.stop();
    count = 0;
    duringCmdSig = false;
  }
}

void ChangeStepDuration(float stepDuration){
  stepTLength = stepDuration;
  stepWriteCount = round(stepTLength*sec2millis);
}


// Parse url for freq
void ChangeFreq(float freq){
  sineFreq = freq;
  cycleEndWriteCount = round(1/sineFreq*sec2millis);
}

void ChangeVoltWriteFloor(int tempVoltFloor){
  Serial.println(tempVoltFloor);
  voltWriteFloor = tempVoltFloor;
  voltWriteRange = CalcVoltWriteRange();
}

void ChangeVoltWriteCeil(int tempVoltCeil){
  voltWriteCeil = tempVoltCeil;
  voltWriteRange = CalcVoltWriteRange();
}



void ParseCommand(){
  // Parse commandStr.  The command number and arguments are seperated by a hyphen
  char * cmdParts[10];
  char * ptr = NULL;
  int partsInd = 0;
  ptr = strtok(commandStr, "-");

  while (ptr != NULL){
    cmdParts[partsInd] = ptr;
    Serial.println(cmdParts[partsInd]);
    partsInd++;
    ptr = strtok(NULL, "-");
  }

  // Convert first command argument, which is the command number, to an int
  int cmd = atoi(cmdParts[0]);
  count = 0; // necessary for all output signals
  if (cmd == UNIDIRECTION_FLEX){
    Serial.println("Unidirection Flex Triggered");
    Timer3.attachInterrupt(UnidirectionFlex);
    Timer3.setPeriod(1000); //period = 1000 microseconds = 1000Hz
    Timer3.start();
  }
  else if (cmd == MULTIDIRECTION_FLEX){
    Serial.println("Multidirection Flex Triggered");
    Timer3.attachInterrupt(MultidirectionFlex);
    Timer3.setPeriod(1000); //period = 1000 microseconds = 1000Hz
    Timer3.start();  }
  else if (cmd == UNIDIRECTION_FLEX_WITH_BOUNDS){
    Serial.println("Uni flex w/ bounds Triggered");
    Timer3.attachInterrupt(UnidirectionFlexWithBounds);
    Timer3.setPeriod(1000); //period = 1000 microseconds = 1000Hz
    Timer3.start();
  }
  else if (cmd == STEP_SIGNAL){
    Serial.println("Step signal Triggered");
    Timer3.attachInterrupt(StepSignal);
    Timer3.setPeriod(1000); //period = 1000 microseconds = 1000Hz
    Timer3.start();
  }
  else if (cmd == CALIBRATION_SIGNAL){
    Serial.println("Calibration signal Triggered");
    Timer3.attachInterrupt(CalibrationSignal);
    Timer3.setPeriod(1000); //period = 1000 microseconds = 1000Hz
    Timer3.start(); 
  }
  else if (cmd == CHANGE_FREQ){
    Serial.println("Change freq Triggered");
    float tempFreq = atof(cmdParts[1]); // converts str of freq arg to float. Returns 0.0 on error
    float tol = 1.0e-8;
    if (abs(tempFreq - 0.0) > tol){
      ChangeFreq(tempFreq);
    }
  }
  else if (cmd == CHANGE_STEP_DURATION){
    Serial.println("Change step duration Triggered");
    float tempTime = atof(cmdParts[1]); // converts str of freq arg to float. Returns 0.0 on error
    float tol = 1.0e-8;
    if (abs(tempTime - 0.0) > tol){
      ChangeStepDuration(tempTime);
    }
  }
  else if (cmd == CHANGE_VOLT_WRITE_FLOOR){
    Serial.println("Change volt write floor Triggered");
    int tempVoltFloor = atoi(cmdParts[1]); // converts str of freq arg to int. Returns 0 on error
    if (tempVoltFloor > 0){
      ChangeVoltWriteFloor(tempVoltFloor);
    }
    else{
      String tempStr = String(cmdParts[1]);
      int i = tempStr.indexOf('0');
      if ( i == 0){
        ChangeVoltWriteFloor(0);
      }
      else{
        char errStr[70];
        sprintf(errStr, "An invalid argument '%s' was given for volt floor argument", cmdParts[1]);
        Serial.println(errStr);
      }
    }
  }
  else if (cmd == CHANGE_VOLT_WRITE_CEIL){
    Serial.println("Change Volt Write Ceil Triggered");
    int tempVoltCeil = atoi(cmdParts[1]); // converts str of freq arg to int. Returns 0 on error
    if (tempVoltCeil > 0){
      ChangeVoltWriteCeil(tempVoltCeil);
    }
    else if (strcmp(cmdParts[1], "0")){
      ChangeVoltWriteCeil(tempVoltCeil);
    }
    else{
      char errStr[70];
      sprintf(errStr, "An invalid argument '%s' was given for volt ceil argument", cmdParts[1]);
      Serial.println(errStr);
    }
  }
  else if (cmd == ERROR_CMD){
    Serial.println("atoi returned 0.  Either a non-numeric char or '0' was sent");
  }
  else{
    Serial.println("The command number you gave does not match anything in Commands enum");
  }
}

void setup() {

  // round() function cannot be used outside of functions or macros so setup
  // must occur in the setup() function
  cycleEndWriteCount = round(1/sineFreq*sec2millis);
  stepWriteCount = round(stepTLength*sec2millis);      //number of times StepSignal will be called before it detaches the Timer3

  Wire.begin();
//
//  // Analog Output Setup
//  analogWriteResolution(12);

  // Serial setup
  Serial.begin(115200);
  Serial.println("Setup done");
  Serial1.begin(115200);
}

void loop() {
  if (duringCmdSig){
    Wire.beginTransmission(MCP4725_ADDR);
    Wire.write(0x40);
    Wire.write(voltWrite >> 4);
    Wire.write((voltWrite & 15) << 4);
    Wire.endTransmission();
//    analogWrite(DAC0, voltWrite); 
  }
  else{
    Wire.beginTransmission(MCP4725_ADDR);
    Wire.write(0x40);
    Wire.write(voltWriteFloor >> 4);
    Wire.write((voltWriteFloor & 15) << 4);
    Wire.endTransmission();    
//    analogWrite(DAC0, voltWriteFloor);  
  }
  
  if (Serial1.available() > 0){
    serInput = Serial1.read();
    Serial.println(serInput);
    if ( serInput == '<' ) {
      serReading = true;
    }
    else if ( serInput == '>'){
      serReading = false;
      serDoneReading = true;
    }
    else if ( serReading ){
      serCmd += serInput;
    }
  }
  if ( serDoneReading ){
    memset(commandStr, 0, sizeof(commandStr));
    serCmd.toCharArray(commandStr, 50);
    Serial.println(commandStr);
    ParseCommand();
    serCmd = "";
    serDoneReading = false;
  }
}
