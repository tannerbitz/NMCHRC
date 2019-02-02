""" Node/Teensy reference signal generation setup API

    Note: You MUST be on the network:
        Network: BetterLateThanNever
        Password: PleaseWork

        If you are not on this network, the http GET requests will
        not work
"""
import requests

baseCmdStr = "http://192.168.0.107/RelayToI2C?Command="

def GenerateUnidirectionFlex():
    cmd = baseCmdStr + "1"
    requests.get(cmd)

def GenerateMultidirectionFlex():
    cmd = baseCmdStr + "2"
    requests.get(cmd)

def GenerateUnidirectionWithBounds():
    cmd = baseCmdStr + "3"
    requests.get(cmd)

def GenerateStep():
    cmd = baseCmdStr + "4"
    requests.get(cmd)

def GenerateCalibrationSignal():
    cmd = baseCmdStr + "5"
    requests.get(cmd)

def ChangeFreq(freqInHz):
    cmd = baseCmdStr + "6-{}".format(freqInHz)
    requests.get(cmd)

def ChangeStepDuration(timeInSeconds):
    cmd = baseCmdStr + "7-{}".format(timeInSeconds)
    requests.get(cmd)

def ChangeVoltWriteFloor(newFloor):
    cmd = baseCmdStr + "8-{}".format(newFloor)
    requests.get(cmd)

def ChangeVoltWriteCeil(newCeil):
    cmd = baseCmdStr + "9-{}".format(newCeil)
    requests.get(cmd)
