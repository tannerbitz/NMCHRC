import time
import serial
import serial.tools.list_ports
import ReferenceSignalGeneratorAPI as RefSigGen
serlist = list(serial.tools.list_ports.comports())

for i in serlist:
    ser = serial.Serial(port = i.device,
                        baudrate = 115200)

def run():
    ser.write(b'<5,0,0>')
    ser.write(b'<0,nodemcutest12.txt>')
    ser.write(b'<6,7,1>')

    # Change Freq = 0.20Hz on Ref Signal Generator (NodeMcu)
    res = RefSigGen.ChangeFreq(0.2)
    if (res == 0):
        print("Timeout occured")
        return

    int2print = 0

    startNodeMcuSignalTimes = [1.0, 11.0, 21.0, 31.0]
    ind = 0;

    start = time.time()
    while True:
        daqstr = "<6, 7, {}>".format(int2print)
        bdaqstr = daqstr.encode('utf-8')
        if (time.time() > start + startNodeMcuSignalTimes[ind]):
            print(startNodeMcuSignalTimes[ind])
            ind = ind+1
            int2print = int2print + 1
            if ind < len(startNodeMcuSignalTimes):
                ser.write(bdaqstr)
                RefSigGen.GenerateUnidirectionWithBounds()
            else:
                break

    ser.write(b'<1>')

run()
