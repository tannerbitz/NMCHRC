#!/usr/bin/python3

import serial.tools.list_ports
ports = serial.tools.list_ports.comports()
for port in ports:
    print(port)

def WriteToSerial(ser, bytestring):
    ser.write(bytestring)
    return

def ReadSerial(ser):
    readstring = ser.read(ser.in_waiting)
    print(readstring)
