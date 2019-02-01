import time
import serial
import serial.tools.list_ports
import requests
serlist = list(serial.tools.list_ports.comports())

for i in serlist:
    ser = serial.Serial(port = i.device,
                        baudrate = 115200)

ser.write(b'<0,nodemcutest1.txt>')
ser.write(b'<6,7,1>')

# Change Freq = 0.20Hz on Ref Signal Generator (NodeMcu)
changefreq = "http://192.168.0.107/ChangeFreq?Freq=0.20"
requests.get(changefreq)

newcycleunitest = "http://192.168.0.107/NewCycleUniTest"

int2print = 0

startNodeMcuSignalTimes = [1.0, 11.0, 21.0, 31.0]
ind = 0;

start = time.time()
while True:
    daqstr = "<6, 7, {}>".format(int2print)
    bdaqstr = daqstr.encode('utf-8')
    if (time.time() > start + startNodeMcuSignalTimes[ind]):
        ind = ind+1
        int2print = int2print + 1
        if ind < len(startNodeMcuSignalTimes):
            ser.write(bdaqstr)
            requests.get(newcycleunitest)
        else:
            break

ser.write(b'<1>')
