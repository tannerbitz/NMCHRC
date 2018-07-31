#!/usr/bin/python3

import datetime
import serial
import time

import serial.tools.list_ports
ports = serial.tools.list_ports.comports()
teensyPort = ""
for port in ports:
    tempPortStr = str(port)
    if (tempPortStr.find("USB Serial") != -1):
        tempStrArray = tempPortStr.split(" ")
        teensyPort = tempStrArray[0]

n = datetime.datetime.now()
bStopStr = b'<1>'
startStr = '<0,TestDaqReadingsNoExternalI2C.txt,{},{},{},{},{},{}>'.format(n.year, n.month, n.day, n.hour, n.minute, n.second)
bStartStr = str.encode(startStr)
bInsertStr1 = b'<6,6,1>'
bInsertStr2 = b'<6,6,2>'
bInsertStr3 = b'<6,6,3>'
bInsertStr4 = b'<6,6,4>'
bInsertStr5 = b'<6,6,5>'
bInsertStr6 = b'<6,6,6>'
bInsertStr7 = b'<6,6,7>'
bInsertStr8 = b'<6,6,8>'


ser = serial.Serial(port=teensyPort, baudrate=115200)
print("Starting")
ser.write(bStartStr)
time.sleep(5)
ser.write(bInsertStr1)
time.sleep(5)
ser.write(bInsertStr2)
time.sleep(5)
ser.write(bInsertStr3)
time.sleep(5)
ser.write(bInsertStr4)
time.sleep(5)
ser.write(bInsertStr5)
time.sleep(5)
ser.write(bInsertStr6)
time.sleep(5)
ser.write(bInsertStr7)
time.sleep(5)
ser.write(bInsertStr8)
time.sleep(5)
ser.write(bStopStr)

print("Done")
