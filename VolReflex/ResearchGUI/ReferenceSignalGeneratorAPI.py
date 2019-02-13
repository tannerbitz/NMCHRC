""" Node/Teensy reference signal generation setup API

    Note: You MUST be on the network:
        Network: BetterLateThanNever
        Password: PleaseWork

        If you are not on this network, the http GET requests will
        not work
"""
import requests

baseCmdStr = "http://192.168.0.107/RelayToI2C?Command="
timeoutval = 0.1

def GenerateUnidirectionFlex():
    cmd = baseCmdStr + "1"
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def GenerateMultidirectionFlex():
    cmd = baseCmdStr + "2"
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def GenerateUnidirectionWithBounds():
    cmd = baseCmdStr + "3"
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def GenerateStep():
    cmd = baseCmdStr + "4"
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def GenerateCalibrationSignal():
    cmd = baseCmdStr + "5"
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def ChangeFreq(freqInHz):
    cmd = baseCmdStr + "6-{}".format(freqInHz)
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def ChangeStepDuration(timeInSeconds):
    cmd = baseCmdStr + "7-{}".format(timeInSeconds)
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def ChangeVoltWriteFloor(newFloor):
    cmd = baseCmdStr + "8-{}".format(newFloor)
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0

def ChangeVoltWriteCeil(newCeil):
    cmd = baseCmdStr + "9-{}".format(newCeil)
    try:
        requests.get(cmd, timeout=timeoutval)
        return
    except requests.exceptions.RequestException:
        return 0
