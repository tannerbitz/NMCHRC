import time
import serial
import serial.tools.list_ports
serlist = list(serial.tools.list_ports.comports())

for i in serlist:
    ser = serial.Serial(port = i.device,
                        baudrate = 115200)

ser.write(b'<0, daqtest3.txt>')
ser.write(b'<6,7,1>')

int2print = 0

start = time.time()
while True:
    daqstr = "<6, 7, {}>".format(int2print)
    bdaqstr = daqstr.encode('utf-8')
    if (time.time() > start + int2print + 1.0):
        ser.write(bdaqstr)
        print("{}, {}".format(int2print, time.time()))
        int2print = int2print + 1
        if int2print == 60:
            break

ser.write(b'<1>')
