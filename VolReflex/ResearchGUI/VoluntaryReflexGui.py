#!/usr/bin/python3

import sys
from PyQt5.QtWidgets import *
from PyQt5 import QtCore, QtGui, QtWidgets, uic, QtTest
from PyQt5.QtCore import QThread, pyqtSignal
import serial.tools.list_ports
import pyqtgraph as pg
import numpy as np
import serial
import datetime
import time
from collections import deque
import random
import ReferenceSignalGeneratorAPI as refSigGen
from scipy import stats
import queue

def getComPorts():
    tempPorts = []
    ports = serial.tools.list_ports.comports()
    for port in ports:
        tempPorts.append(str(port))
    return tempPorts

def isStringAnInt(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

# Serial Object
serialbaudrate = 115200
serialtimeout = 1
serval2torqueNm = (125.0/2048.0)*(4.44822/1.0)*(0.15) #(125lbs/2048points)*(4.44822N/1lbs)*(0.15m)



# Global Data
referencesignalchannel = None
measuredsignalchannel = None
topborder = None
bottomborder = None
mvctable = {'pf': None, 'df': None, 'dfpf': None}
percentmvc = 0.3
volreflexflexion = None
refsignaltype = None
refsignalfreq = None
serialvals = None
calibrationReferenceMeasurements = []
refrawmax = None
refrawmin = None
refrawspan = None
calibrationCompleteFlag = False
serialQueue = queue.Queue(maxsize=3) #getting data at 180hz into queue, pulling at 60hz



# Populate dictionary for automatic trials
autotrial_dict = {}
for i in range(1, 11):
    autotrial_dict[i] = ["PF", i*0.2]
    autotrial_dict[i+10] = ["DF", i*0.2]

# Automatic trial sequences
trial_seq = np.array([[ 19,	3 ,	16,	14,	11,	6 ,	7 ,	12,	18,	20,	5 ,	4 ,	13,	17,	15,	1 ,	2 ,	9 ,	10,	8 ],
                      [ 7 ,	15,	14,	5 ,	6 ,	19,	13,	11,	16,	2 ,	17,	18,	12,	9 , 20,	1 ,	10,	4 ,	3 ,	8 ],
                      [ 7 ,	10,	5 ,	18,	16,	3 ,	11,	12,	6 ,	19,	4 ,	1 ,	20,	15,	9 ,	13,	14,	17,	8 ,	2 ],
                      [ 14,	13,	12,	10,	5 ,	20,	3 ,	8 ,	6 ,	16,	18,	19,	9 ,	11,	17,	1 ,	4 ,	2 ,	7 ,	15],
                      [ 18,	10,	5 ,	19,	13,	1 ,	8 ,	17,	16,	15,	12,	11,	6 ,	9 ,	7 ,	2 ,	3 ,	14,	20,	4 ],
                      [ 8 ,	12,	20,	11,	19,	7 ,	3 ,	5 ,	1 ,	15,	10,	18,	2 ,	14,	13,	17,	9 ,	6 ,	4 ,	16]])



class SerialThread(QThread):
    # Signals
    supplyDaqReadings = pyqtSignal(list)
    supplyMessage = pyqtSignal(str)

    # Class Data
    _ser = None
    _serialTimer = None
    _serIsRunning = False
    _voltRanges = {'ZERO_TO_FIVE':0,
                   'NEG_FIVE_TO_FIVE':1,
                   'ZERO_TO_TEN':2,
                   'NEG_TEN_TO_TEN':3}

    def __init__(self):
        QThread.__init__(self)
        try:
            # Setup Serial Timer To Get and Emit Serial Readings. Timer not started til later.
            self._serialTimer = QtCore.QTimer()
            self._serialGetFreq = 180.0
            self._serialTimer.setInterval(1.0/self._serialGetFreq*1000.0)
            self._serialTimer.timeout.connect(self.getDaqReadings)
        except:
            self.supplyMessage.emit("Error Occured During Timer Setup")

    def resetSerial(self, serialPort, serialBaudrate, serialTimeout):
        # Stop Timer From Getting Serial Data and Emitting It
        self._serialTimer.stop()

        # Close serial connection if it's connected
        if isinstance(self._ser, serial.Serial):
            try:
                self._ser.close()
            except:
                self.supplyMessage.emit("Closing Serial Caused an Error")

        # Reconnect serial
        try:
            self._ser = serial.Serial(port=serialPort, baudrate=serialbaudrate, timeout=serialtimeout)
            self.supplyMessage.emit("Connected")
            self._serIsRunning = True
        except serial.SerialException as e:
            self.supplyMessage.emit("Serial Exception Occured")
            self._serIsRunning = False
        except:
            self.supplyMessage.emit("Something Bad Happened")
            self._serIsRunning = False

        # Restart Serial Timer
        if (self._serIsRunning):
            self._serialTimer.start()

    def getDaqReadings(self):
        try:
            self._ser.write(b'<2>')
            endtime = time.time() + 0.5
            serialstring = ""
            while (time.time() < endtime):
                newchar = self._ser.read().decode()
                serialstring += newchar
                if (newchar == '>'):
                    break
            serialstring = serialstring.strip('<>')
            vals = serialstring.split(',')
            vals = list(map(lambda x: int(x), vals)) # convert str to int
            if (len(vals) == 8):
                self.supplyDaqReadings.emit(vals)
            else:
                self.supplyMessage.emit("Serial Vals Requested. \nReceived: {}".format(serialstring))
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except:
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def startSdWrite(self, filename):
        # DAQ Command to Start a Write is <0,filename,YEAR,MONTH,DAY,HOUR,MINUTE,SECOND>
        n = datetime.datetime.now()
        cmdStr = "<0,{},{},{},{},{},{},{}>".format(filename, n.year, n.month, n.day, n.hour, n.minute, n.second)
        bCmdStr = str.encode(cmdStr, 'utf-8')
        try:
            self._ser.write(bCmdStr)
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except:
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def stopSdWrite(self):
        # DAQ Command to Start a Write is <1>
        bCmdStr = str.encode("<1>", 'utf-8')
        try:
            self._ser.write(bCmdStr)
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except:
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)


    def changeVoltageRange(self, channel, voltRangeInt):
        # DAQ Command to Change Voltage has the form <5,channel,voltRangeInt>
        cmdStr = "<5,{},{}>".format(channel, voltRangeInt)
        bCmdStr = str.encode(cmdStr, 'utf-8')
        try:
            self._ser.write(bCmdStr)
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except:
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def insertValIntoDaqReadings(self, channel, val):
        # DAQ Command to Start a Write is <6,channel,val>
        cmdStr = "<6,{},{}>".format(channel, val)
        bCmdStr = str.encode(cmdStr, 'utf-8')
        try:
            self._ser.write(bCmdStr)
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except:
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def resetI2CDeviceSettings(self):
        # DAQ Command to Start a Write is <7>
        bCmdStr = str.encode("<7>", 'utf-8')
        try:
            self._ser.write(bCmdStr)
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except:
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def isSDCardInserted(self):
        # DAQ Command to Start a Write is <8>
        bCmdStr = str.encode("<8>", 'utf-8')
        try:
            self._ser.write(bCmdStr)
            endtime = time.time() + 0.5
            serialstring = ""
            while (time.time() < endtime):
                newchar = self._ser.read().decode()
                serialstring += newchar
                if (newchar == '>'):
                    break
            serialstring = serialstring.strip('<>')
            if (serialstring == "True"):
                return True
            elif (serialstring == "False"):
                return False
            else:
                self.supplyMessage.emit("Unexpected value received during isSDCardInserted method")
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except:
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)


class MainWindow(QtWidgets.QMainWindow):

    # Class Data

    # Setting Data
    _patientnumber = None
    _daqport = None
    _serialstatus = None

    # MVC Trial Data
    _mvctrialflexion = None
    _mvctrialfilename = None
    _mvcfiletoimport = None
    _mvctrialcounter = 0
    _mvctrialrepetition = 0
    _mvctimer = None

    # MVC import
    _mvcdffile = None
    _mvcpffile = None

    # Voluntary Reflex Trial data
    _volreflexankleposition = None
    _volreflexfilename = None
    _volreflexreferencesignal = None
    _volreflextrialnumber = None

    # Auto Trial Numbers
    _autotrialround = 1
    _autotrialnumber = 1
    _autotrialcounter = 0
    _autotrialcountermin = 0
    _autotrialcountermax = 119
    _trialsperround = 20
    _autotrialflexion = None
    _autotrialsinefreq = None

    # Serial
    _serialThread = None

    def __init__(self):
        super(MainWindow, self).__init__()
        ag = QDesktopWidget().availableGeometry()
        self.setGeometry(0, 0, 1366, 650)
        uic.loadUi('ResearchGui.ui', self)
        self.show()
        self.startSettingsTab()

    # Initialize Settings Tab Lists
    def refreshComPortList(self):
        self.list_comport.clear()
        ports = getComPorts()
        for port in ports:
            self.list_comport.addItem(port)

    def initReferenceSignalList(self):
        self.list_referencesignal.clear()
        for channel in range(0,8):
            self.list_referencesignal.addItem("Channel {}".format(channel))

    def initMeasuredSignalList(self):
        self.list_measuredsignal.clear()
        for channel in range(0,8):
            self.list_measuredsignal.addItem("Channel {}".format(channel))

    # Button functions
    def selectDaqPort(self):
        portobj = self.list_comport.selectedItems()
        for i in list(portobj):
            selectedport = str(i.text())
        selectedportparts = selectedport.split(" ")
        self._daqport = selectedportparts[0]
        self.lbl_daqport.setText(self._daqport)


    def selectReferenceSignalChannel(self):
        global referencesignalchannel
        channelobj = self.list_referencesignal.selectedItems()
        for i in list(channelobj):
            selectedchannel = str(i.text())
        selectedchannelparts = selectedchannel.split(" ")
        referencesignalchannel = int(selectedchannelparts[1])
        self.lbl_referencesignal.setText("Channel {}".format(referencesignalchannel))

    def selectMeasuredSignalChannel(self):
        global measuredsignalchannel
        channelobj = self.list_measuredsignal.selectedItems()
        for i in list(channelobj):
            selectedchannel = str(i.text())
        selectedchannelparts = selectedchannel.split(" ")
        measuredsignalchannel = int(selectedchannelparts[1])
        self.lbl_measuredsignal.setText("Channel {}".format(measuredsignalchannel))

    def setPatientNumber(self):
        tempStr = self.lineedit_patientnumber.text()
        self.lbl_patientnumbererror.setAlignment(QtCore.Qt.AlignRight | QtCore.Qt.AlignVCenter)
        if (isStringAnInt(tempStr)):
            tempInt = int(tempStr)
            if (tempInt >= 0 and tempInt <= 99 ):
                self._patientnumber = tempInt
                self.lbl_patientnumber.setText("{}".format(self._patientnumber))
                self.lbl_patientnumbererror.setText("")
                self.completeMvcTrialFilename()
                self.completeVoluntaryReflexFilename()
            else:
                self._patientnumber = None
                self.lbl_patientnumber.setText("")
                self.lbl_patientnumbererror.setText("Integer Must Be Between 0-99")
        else:
            self._patientnumber = None
            self.lbl_patientnumber.setText("")
            self.lbl_patientnumbererror.setText("Patient Number Must Be An Integer")

    def resetSerialOnThread(self):
        if (self._daqport is None):
            self.lbl_daqportstatus.setText("Select COM Port")
        else:
            if (self._serialThread is None):
                self._serialThread = SerialThread()
                self._serialThread.supplyMessage.connect(self.printToDaqPortStatus)
                self._serialThread.supplyDaqReadings.conect(self.putInSerialQueue)
            self._serialThread.resetSerial(self._daqport, serialbaudrate, serialtimeout)

    def putInSerialQueue(self, vals):
        global serialQueue
        if (serialQueue.full()):
            serialQueue.get()
            serialQueue.put(vals)
        else:
            serialQueue.put(vals)

    def printToTerminal(self, vals):
        print(vals)

    def printToDaqPortStatus(self, inStr):
        self.lbl_daqportstatus.setText(inStr)


    def setMvcTrialFlexion(self, btn_mvcflexion):
        tempStr = btn_mvcflexion.text()
        if ( tempStr == "Plantarflexion" ):
            self._mvctrialflexion = "PF"
        elif (tempStr == "Dorsiflexion" ):
            self._mvctrialflexion = "DF"
        self.completeMvcTrialFilename()

    def completeMvcTrialFilename(self):
        if (self._patientnumber is not None and self._mvctrialflexion is not None):
            self._mvctrialfilename = "Patient{}_MVC_{}.txt".format(self._patientnumber, self._mvctrialflexion)
            self.lbl_mvcmeasurementfilename.setText(self._mvctrialfilename)
        else:
            self._mvctrialfilename = None
            self.lbl_mvcmeasurementfilename.setText("Complete Settings")


    def startMvcTrial(self):
        # Exit routine if settings aren't complete
        if (self.lbl_mvcmeasurementfilename.text() == "Complete Settings"):
            self.lbl_mvctriallivenotes.setText("Complete Settings")
            return

        # Check if serial is connected and SD Card is inserted
        if (self._serialThread._serIsRunning == False):
            self.lbl_mvctriallivenotes.setText("Connect Serial Before Proceeding")
            return

        if (self._serialThread.isSDCardInserted() == False):
            self.lbl_mvctriallivenotes.setText("Insert SD Card")
            return

        # Start Writing Process
        self._serialThread.startSdWrite(self._mvctrialfilename)

        self._mvctrialcounter = 0
        self._mvctrialrepetition = 0
        self._mvctimer = QtCore.QTimer()
        self._mvctimer.timeout.connect(self.mvcTrialHandler)
        self._mvctimer.start(1000)

    def mvcTrialHandler(self):
        firstrestend = 5
        firstflexend = firstrestend + 5
        secondrestend = firstflexend + 15
        secondflexend = secondrestend + 5
        thirdrestend = secondflexend + 15
        thirdflexend = thirdrestend + 5
        if (self._mvctrialflexion == "DF"):
            flexstr = "Pull"
        elif (self._mvctrialflexion == "PF"):
            flexstr = "Push"
        if (self._mvctrialcounter < firstrestend):
            self._serialThread.insertValIntoDaqReadings(6, 0) #insert 0 into 6th channel
            self.lbl_mvctriallivenotes.setText("{} in {}".format(flexstr, firstrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstrestend and self._mvctrialcounter < firstflexend):
            self._serialThread.insertValIntoDaqReadings(6, 1) #insert 1 into 6th channel
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(firstflexend - self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstflexend and self._mvctrialcounter < secondrestend):
            self._serialThread.insertValIntoDaqReadings(6, 0)
            self.lbl_mvctriallivenotes.setText("Rest.  {} in {}".format(flexstr, secondrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= secondrestend and self._mvctrialcounter < secondflexend):
            self._serialThread.insertValIntoDaqReadings(6, 1)
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(secondflexend - self._mvctrialcounter))
        elif (self._mvctrialcounter >= secondflexend and self._mvctrialcounter < thirdrestend):
            self._serialThread.insertValIntoDaqReadings(6, 0)
            self.lbl_mvctriallivenotes.setText("Rest.  {} in {}".format(flexstr, thirdrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= thirdrestend and self._mvctrialcounter < thirdflexend):
            self._serialThread.insertValIntoDaqReadings(6, 1)
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(thirdflexend - self._mvctrialcounter))
        else:
            self._serialThread.stopSdWrite()
            self.lbl_mvctriallivenotes.setText("Done")
            self._mvctimer.stop()
            self._mvctimer.deleteLater()

        self._mvctrialcounter += 1

    def setDfPfMvc(self):
        global mvctable
        if mvctable['pf'] is not None and mvctable['df'] is not None:
            mvctable['dfpf'] = np.mean([abs(mvctable['pf']), abs(mvctable['df'])])
        else:
            mvctable['dfpf'] = None

    def customizeSetupTab(self):
        # Expand table widget column
        self.tablewidget_mvc.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)

        # Setup MVC Trial Flexion Button Group
        self.mvctrialflexionbuttongroup = QButtonGroup(self)
        self.mvctrialflexionbuttongroup.addButton(self.rbtn_mvcmeasurementpf)
        self.mvctrialflexionbuttongroup.addButton(self.rbtn_mvcmeasurementdf)
        self.mvctrialflexionbuttongroup.buttonClicked.connect(self.setMvcTrialFlexion)

    def customizeVoluntaryReflexMeasurementTab(self):
        # Add pyqtgraph plot

        # Set axes properties
        xAxisItem = pg.AxisItem(orientation='bottom', showValues=False)
        yAxisItem = pg.AxisItem(orientation='left', showValues=True)
        xAxisItem.showLabel(False)
        yAxisItem.showLabel(False)

        # Initialize plot
        pg.setConfigOption('background', 'w')
        pg.setConfigOption('foreground', 'k')
        self.plotwin = pg.GraphicsLayoutWidget()
        self.layout_pyqtgraph.addWidget(self.plotwin)
        self.plt = self.plotwin.addPlot(row=0, col=0, rowspan=1, colspan=1, axisItems={'left': yAxisItem, 'bottom': xAxisItem})
        self.plt.setRange(xRange=(0, 1), yRange=(-1, 1), padding=0.0)

        # Init lines
        self.reference_line = pg.PlotCurveItem()
        self.measured_line = pg.PlotCurveItem()
        self.zero_line = pg.PlotCurveItem()
        self.target_line = pg.PlotCurveItem()
        self.target_line2 = pg.PlotCurveItem()

        # Define line properties and set properties
        reference_line_pen = pg.mkPen(color='c', width=30, style=QtCore.Qt.SolidLine)
        measured_line_pen = pg.mkPen(color='r', width=10, style=QtCore.Qt.SolidLine)
        zero_line_pen = pg.mkPen(color='k', width=5, style=QtCore.Qt.DashLine)
        target_line_pen = pg.mkPen(color='k', width=5, style=QtCore.Qt.DashLine)

        self.measured_line.setPen(measured_line_pen)
        self.zero_line.setPen(zero_line_pen)
        self.reference_line.setPen(reference_line_pen)
        self.target_line.setPen(target_line_pen)
        self.target_line2.setPen(target_line_pen)

        # Set lines in initial position
        xdata = np.array([0, 1])
        ydata = np.array([0, 0])
        self.reference_line.setData(x=xdata, y=ydata)
        self.measured_line.setData(x=xdata, y=ydata)
        self.zero_line.setData(x=xdata, y=ydata)
        self.target_line.setData(x=xdata, y=ydata)
        self.target_line2.setData(x=xdata, y=ydata)

        # Add lines to plot
        self.plt.addItem(self.reference_line)
        self.plt.addItem(self.measured_line)
        self.plt.addItem(self.zero_line)
        self.plt.addItem(self.target_line)
        self.plt.addItem(self.target_line2)

        # Redo Ankle Position Radiobutton text
        self.rbtn_volreflex5pf.setText(u' 5\N{DEGREE SIGN} PF')
        self.rbtn_volreflex10pf.setText(u'10\N{DEGREE SIGN} PF')
        self.rbtn_volreflex15pf.setText(u'15\N{DEGREE SIGN} PF')
        self.rbtn_volreflex20pf.setText(u'20\N{DEGREE SIGN} PF')
        self.rbtn_volreflex0.setText(u' 0\N{DEGREE SIGN}')
        self.rbtn_volreflex5df.setText(u' 5\N{DEGREE SIGN} DF')
        self.rbtn_volreflex10df.setText(u'10\N{DEGREE SIGN} DF')

        # Group Ankle Position RadioButtons
        self.volreflexanklepositionbuttongroup = QButtonGroup(self)
        self.volreflexanklepositionbuttongroup.addButton(self.rbtn_volreflex5pf)
        self.volreflexanklepositionbuttongroup.addButton(self.rbtn_volreflex10pf)
        self.volreflexanklepositionbuttongroup.addButton(self.rbtn_volreflex15pf)
        self.volreflexanklepositionbuttongroup.addButton(self.rbtn_volreflex20pf)
        self.volreflexanklepositionbuttongroup.addButton(self.rbtn_volreflex0)
        self.volreflexanklepositionbuttongroup.addButton(self.rbtn_volreflex5df)
        self.volreflexanklepositionbuttongroup.addButton(self.rbtn_volreflex10df)
        self.volreflexanklepositionbuttongroup.buttonClicked.connect(self.setVoluntaryReflexAnklePosition)

        # Group Voluntary Reflex Flexion RadioButtons
        self.volreflexflexionbuttongroup = QButtonGroup(self)
        self.volreflexflexionbuttongroup.addButton(self.rbtn_volreflexdf)
        self.volreflexflexionbuttongroup.addButton(self.rbtn_volreflexpf)
        self.volreflexflexionbuttongroup.addButton(self.rbtn_volreflexdfpf)
        self.volreflexflexionbuttongroup.buttonClicked.connect(self.setVoluntaryReflexFlexion)

        # Group Voluntary Reflex Sinusoid Freqency RadioButtons
        self.volreflexrefsigbtngroup = QButtonGroup(self)
        # Sinusoid Buttons
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig1) #0.2 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig2) #0.4 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig3) #0.6 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig4) #0.8 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig5) #1.0 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig6) #1.2 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig7) #1.4 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig8) #1.6 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig9) #1.8 Hz
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig10) #2.0 Hz

        # Other reference signal radiobutons
        self.volreflexrefsigbtngroup.addButton(self.rbtn_refsig_step) #Step

        self.volreflexrefsigbtngroup.buttonClicked.connect(self.setReferenceSignal)

        # Connect Trial Spinbox
        self.spinboxtrialnumber.valueChanged.connect(self.setVoluntaryReflexTrialNumber)

        # Trial Settings Button Group
        self.trialsettingsbtngroup = QButtonGroup(self)
        self.trialsettingsbtngroup.addButton(self.rbtn_autotrial)
        self.trialsettingsbtngroup.addButton(self.rbtn_manualtrial)
        self.trialsettingsbtngroup.buttonClicked.connect(self.setTrialSettingsMode)
        self.setAutoTrial()

    def setAutoTrialFlexFreq(self):
        trial_number = trial_seq[self._autotrialround-1][self._autotrialnumber-1]
        trial_list = autotrial_dict[trial_number]
        self._autotrialflexion = trial_list[0]
        self._autotrialsinefreq =  trial_list[1]

    def setAutoTrial(self):
        self.setAutoTrialFlexFreq()
        self.setAutoTrialLabels()

    def setTrialSettingsMode(self, btn_chosen):
        btntext = btn_chosen.objectName()
        if btntext == "rbtn_autotrial":
            self.enableAutoTrialSettings()
            self.disableManualTrialSettings()
        elif btntext == "rbtn_manualtrial":
            self.disableAutoTrialSettings()
            self.enableManualTrialSettings()

    def getAutoWidgetList(self):
        return [self.label_11,
               self.label_7,
               self.label_round,
               self.label_trial,
               self.label_trialname,
               self.btn_nexttrial,
               self.btn_prevtrial,
               self.groupbox_autotrial]

    def getManualWidgetList(self):
        return [self.rbtn_volreflex0,
                self.rbtn_volreflex10df,
                self.rbtn_volreflex10pf,
                self.rbtn_volreflex15pf,
                self.rbtn_volreflex20pf,
                self.rbtn_volreflex5df,
                self.rbtn_volreflex5pf,
                self.rbtn_volreflexdf,
                self.rbtn_volreflexpf,
                self.rbtn_volreflexdfpf,
                self.rbtn_refsig1,
                self.rbtn_refsig2,
                self.rbtn_refsig3,
                self.rbtn_refsig4,
                self.rbtn_refsig5,
                self.rbtn_refsig6,
                self.rbtn_refsig7,
                self.rbtn_refsig8,
                self.rbtn_refsig9,
                self.rbtn_refsig10,
                self.spinboxtrialnumber,
                self.label,
                self.lbl_trialflexionmvc,
                self.rbtn_refsig_step,
                self.groupbox_manualtrial,
                self.groupbox_refsignal,
                self.groupbox_ankleposition,
                self.groupbox_volreflexflexion,
                self.groupbox_refsignal,
                self.groupbox_sinusoid,
                self.groupbox_other,
                self.groupbox_trialnumber]

    def enableAutoTrialSettings(self):
        widgetlist_auto = self.getAutoWidgetList()

        for item in widgetlist_auto:
            item.setEnabled(True)

    def enableManualTrialSettings(self):
        widgetlist_manual = self.getManualWidgetList()

        for item in widgetlist_manual:
            item.setEnabled(True)

    def disableAutoTrialSettings(self):
        widgetlist_auto = self.getAutoWidgetList()

        for item in widgetlist_auto:
            item.setEnabled(False)

    def disableManualTrialSettings(self):
        widgetlist_manual = self.getManualWidgetList()

        for item in widgetlist_manual:
            item.setEnabled(False)

    def minimizeWindow(self):
        self.showNormal()
        self.showMinimized()

    def maximizeWindow(self):
        self.showNormal()
        self.showMaximized()

    def closeWindow(self):
        QApplication.quit()

    def setVoluntaryReflexTrialNumber(self, newvalue):
        if (newvalue == 0):
            self._volreflextrialnumber = None
        else:
            self._volreflextrialnumber = int(newvalue)
        self.completeVoluntaryReflexFilename()

    def setReferenceSignal(self, btn_volreflexreferencesignal):
        global refsignaltype
        global refsignalfreq
        btntext = btn_volreflexreferencesignal.text()
        if (btntext == "Step"):
            refsignaltype = 'step'
            refsignalfreq = None
            self._volreflexreferencesignal = btntext
        else:
            refsignaltype = 'sine'
            # get sinusoid frequency
            freqtext = btntext
            hzind = freqtext.find('Hz')
            freqtext = freqtext[0:hzind]
            refsignalfreq = float(freqtext)

            # Change Freq on Ref Signal Generator (NodeMcu)
            res = refSigGen.ChangeFreq(refsignalfreq)
            if (res == 0):
                msgbox = QMessageBox(text="Please Connect To:\n\nNetwork: BetterLateThanNever\nPassword: PleaseWork")
                msgbox.exec_()

            # make frequency info ready to add to filename
            btntext = btntext.replace(" ", "")
            self._volreflexreferencesignal = btntext.replace(".", "-")
        self.completeVoluntaryReflexFilename()

    def setVoluntaryReflexAnklePosition(self, btn_volreflexankleposition):
        tempAnklePosition = btn_volreflexankleposition.objectName()
        if ( tempAnklePosition == "rbtn_volreflex0" ):
            self._volreflexankleposition = "Neutral"
        elif ( tempAnklePosition == "rbtn_volreflex5df"):
            self._volreflexankleposition = "5DF"
        elif ( tempAnklePosition == "rbtn_volreflex10df"):
            self._volreflexankleposition = "10DF"
        elif ( tempAnklePosition == "rbtn_volreflex5pf"):
            self._volreflexankleposition = "5PF"
        elif ( tempAnklePosition == "rbtn_volreflex10pf"):
            self._volreflexankleposition = "10PF"
        elif ( tempAnklePosition == "rbtn_volreflex15pf"):
            self._volreflexankleposition = "15PF"
        elif ( tempAnklePosition == "rbtn_volreflex20pf"):
            self._volreflexankleposition = "20PF"
        else:
            self._volreflexankleposition = None
        self.completeVoluntaryReflexFilename()

    def setVoluntaryReflexFlexion(self, btn_volreflexflexion):
        global topborder
        global bottomborder
        global mvctable
        global percentmvc
        global volreflexflexion
        global refsignalmax
        global refsignalmin
        global refsignalspan
        tempFlexion = btn_volreflexflexion.text()
        refsignalmin = 0
        refsignalmax = 0
        if ( tempFlexion == "Plantarflexion"):
            volreflexflexion = "PF"
            if (mvctable['pf'] is None):
                self.lbl_volreflexlivenotes.setText('Import PF MVC Trial Readings')
                return
            else:
                #Set Plot Ranges for Test
                self.lbl_trialflexionmvc.setText(str(round(mvctable['pf'],2)))
                refsignalmax = 0
                refsignalmin = -(percentmvc*mvctable['pf'])
                refsignalspan = abs(refsignalmax - refsignalmin)
                topborder = refsignalmax+0.3*refsignalspan
                bottomborder = refsignalmin-0.6*refsignalspan
                self.plt.setRange(xRange=(0,1), yRange=(bottomborder, topborder), padding=0.0)
        elif (tempFlexion == "Dorsiflexion" ):
            volreflexflexion = "DF"
            if (mvctable['df'] is None):
                self.lbl_volreflexlivenotes.setText('Import DF MVC Trial Readings')
                return
            else:
                #Set Plot Ranges for Test
                self.lbl_trialflexionmvc.setText(str(round(mvctable['df'],2)))
                refsignalmax = (percentmvc*mvctable['df'])
                refsignalmin = 0
                refsignalspan = abs(refsignalmax - refsignalmin)
                topborder = refsignalmax+0.6*refsignalspan
                bottomborder = refsignalmin-0.3*refsignalspan
                self.plt.setRange(xRange=(0,1), yRange=(bottomborder, topborder), padding=0.0)
        elif (tempFlexion == "Dorsiflexion-Plantarflexion"):
            volreflexflexion = "DFPF"
            if (mvctable['dfpf'] is None):
                self.lbl_volreflexlivenotes.setText('Import DF and PF MVC Trial Readings')
                return
            else:
                avgmvc = mvctable['dfpf']
                self.lbl_trialflexionmvc.setText(str(round(avgmvc, 2)))
                refsignalmax = percentmvc*avgmvc
                refsignalmin = -percentmvc*avgmvc
                refsignalspan = abs(refsignalmax - refsignalmin)
                topborder = refsignalmax+0.3*refsignalspan
                bottomborder = refsignalmin-0.3*refsignalspan
                self.plt.setRange(xRange=(0,1), yRange=(bottomborder, topborder), padding=0.0)
        else:
            volreflexflexion = None

        # Set upper and lower target lines
        self.target_line.setData(x=np.array([0,1]),
                                    y=np.array([refsignalmin, refsignalmin]))
        self.target_line2.setData(x=np.array([0,1]),
                                   y=np.array([refsignalmax, refsignalmax]))
        self.plt.update()
        self.completeVoluntaryReflexFilename()

    def completeVoluntaryReflexFilename(self):
        global volreflexflexion
        # Check if Ankle Position, Flexion and Patient Number are set. If not, exit routine
        if (self._volreflexankleposition is None or volreflexflexion is None or self._patientnumber is None):
            self.lbl_volreflexfilename.setText("Complete Settings")
            return

        self._volreflexfilename = "PatNo{}_VR_AnklePos{}_{}".format(self._patientnumber, self._volreflexankleposition, volreflexflexion)
        # Optional parameters
        if (self._volreflexreferencesignal is not None):
            self._volreflexfilename = self._volreflexfilename + "_{}".format(self._volreflexreferencesignal)
        if (self._volreflextrialnumber is not None):
            self._volreflexfilename = self._volreflexfilename + "_Trial{}".format(self._volreflextrialnumber)
        # Finalize filename
        self._volreflexfilename = self._volreflexfilename + ".txt"
        self.lbl_volreflexfilename.setText(self._volreflexfilename)



    def calibraterefsignal(self):
        """
        The reference signal is being generated on a 12-bit DAC.  Therefore
        the input to the DAC is 0-4095.  After this analog signal goes through
        an op-amp it should be amplified to 0-5V.  The DAQ that reads this signal
        can have an internal bias that creates saturation at the low and high ends
        of the signal.  For instance, the DAC signal generated with an input of 0
        and 100 may both be read as 0 by the DAQ's ADC.  This code attempts to find
        the values at which the saturation ends and sets the Teensy's DAC input
        limits to those values.

        To do this, we will first set the floor and ceiling to 0 and 4095 then
        take samples of the DAQ measurements at those voltages.  We will then take
        measurements 1024 above the floor and below the ceil and compare those
        samples data to the floor and ceil samples with a t-test.  We will then
        perform a bi-section method to hone in on the values that correspond to the
        DAQ's saturation limits.
        """

        global refrawmin
        global refrawmax
        global refrawspan
        global calibrationCompleteFlag

        # Check if serial is running and if reference and measured signal channels have been set
        if (self._serialThread._serIsRunning == False):
            self.lbl_volreflexlivenotes.setText('Serial Is Not Running')
            return

        if (referencesignalchannel is None):
            self.lbl_volreflexlivenotes.setText('Set Reference Signal Channel')
            return

        #Begin Calibration
        voltfloor_low = 0
        voltfloor_high = 2047
        voltceil_low = 2048
        voltceil_high = 4095

        # Make DAQ of reference signal channel measure 0-5V
        self._serialThread.changeVoltageRange(referencesignalchannel,
                                              self._serialThread._voltRanges['ZERO_TO_FIVE'])

        # Set Teensy Volt Floor = 0, Volt Ceil = 4095
        self._calFloorSamples = []
        self._calCeilSamples = []

        res = refSigGen.ChangeVoltWriteFloor(voltfloor_low)
        if (res == 0):
            msgbox = QMessageBox(text="Please Connect To:\n\nNetwork: BetterLateThanNever\nPassword: PleaseWork")
            msgbox.exec_()
            return
        refSigGen.ChangeVoltWriteCeil(voltceil_high)
        refSigGen.GenerateCalibrationSignal()

        # Calibration signal lasts 1 sec.  First 500ms is floor volt, last 500ms is ceil volt
        QtTest.QTest.qWait(125) #From 125ms - 375ms collect floor samples
        self._serialThread.supplyDaqReadings.connect(self.appendToCalFloorSamples) #this slot appends ref sig readings to a list
        QtTest.QTest.qWait(250)
        self._serialThread.supplyDaqReadings.disconnect()
        QtTest.QTest.qWait(250) #From 625ms - 875ms collect ceil samples
        self._serialThread.supplyDaqReadings.connect(self.appendToCalCeilSamples) #this slot appends ref sig readings to a list
        QtTest.QTest.qWait(250)
        self._serialThread.supplyDaqReadings.disconnect()

        voltfloorsamples_low = self._calFloorSamples
        voltceilsamples_high = self._calCeilSamples

        nCycles = 10
        for iCycle in range(0, nCycles):
            self.lbl_volreflexlivenotes.setText("Calibration Cycle\n{} of {}".format(iCycle+1, nCycles))

            voltfloor_test = int((voltfloor_low + voltfloor_high)/2)
            voltceil_test = int((voltceil_low + voltceil_high)/2)

            # Set Teensy Volt Floor = 0, Volt Ceil = 4095
            self._calFloorSamples = []
            self._calCeilSamples = []

            refSigGen.ChangeVoltWriteFloor(voltfloor_test)
            refSigGen.ChangeVoltWriteCeil(voltceil_test)
            refSigGen.GenerateCalibrationSignal()

            # Calibration signal lasts 1 sec.  First 500ms is floor volt, last 500ms is ceil volt
            QtTest.QTest.qWait(125) #From 125ms - 375ms collect floor samples
            self._serialThread.supplyDaqReadings.connect(self.appendToCalFloorSamples) #this slot appends ref sig readings to a list
            QtTest.QTest.qWait(250)
            self._serialThread.supplyDaqReadings.disconnect()
            QtTest.QTest.qWait(250) #From 625ms - 875ms collect ceil samples
            self._serialThread.supplyDaqReadings.connect(self.appendToCalCeilSamples) #this slot appends ref sig readings to a list
            QtTest.QTest.qWait(250)
            self._serialThread.supplyDaqReadings.disconnect()

            voltfloorsamples_test = self._calFloorSamples
            voltceilsamples_test = self._calCeilSamples

            # t-test (Welch's t-test)
            # Floor
            [t, p] = stats.ttest_ind(a=voltfloorsamples_low,
                                     b=voltfloorsamples_test,
                                     axis=0,
                                     equal_var=False)

            if (p < 0.98):
                voltfloor_high = voltfloor_test
            else:
                voltfloor_low = voltfloor_test
                voltfloorsamples_low = voltfloorsamples_test

            # Ceil
            [t, p] = stats.ttest_ind(a=voltceilsamples_high,
                                     b=voltceilsamples_test,
                                     axis=0,
                                     equal_var=False)

            if (p < 0.98):
                voltceil_low = voltceil_test
            else:
                voltceil_high = voltceil_test
                voltceilsamples_high = voltceilsamples_test

            print("cycle {}: floor: {} ceil: {}".format(iCycle, voltfloor_low, voltceil_high))

        # Move 10 inside of floor and ceil to make floor for noise in data
        voltfloor = voltfloor_low + 10
        voltceil = voltceil_high - 10

        # Set Teensy Volt Floor = 0, Volt Ceil = 4095
        self._calFloorSamples = []
        self._calCeilSamples = []

        refSigGen.ChangeVoltWriteFloor(voltfloor)
        refSigGen.ChangeVoltWriteCeil(voltceil)
        refSigGen.GenerateCalibrationSignal()

        # Calibration signal lasts 1 sec.  First 500ms is floor volt, last 500ms is ceil volt
        QtTest.QTest.qWait(125) #From 125ms - 375ms collect floor samples
        self._serialThread.supplyDaqReadings.connect(self.appendToCalFloorSamples) #this slot appends ref sig readings to a list
        QtTest.QTest.qWait(250)
        self._serialThread.supplyDaqReadings.disconnect()
        QtTest.QTest.qWait(250) #From 625ms - 875ms collect ceil samples
        self._serialThread.supplyDaqReadings.connect(self.appendToCalCeilSamples) #this slot appends ref sig readings to a list
        QtTest.QTest.qWait(250)
        self._serialThread.supplyDaqReadings.disconnect()

        refrawmin = np.min(self._calFloorSamples)
        refrawmax = np.max(self._calCeilSamples)
        refrawspan = abs(refrawmax - refrawmin)

        calibrationCompleteFlag = True
        self.lbl_calmin.setText(str(refrawmin))
        self.lbl_calmax.setText(str(refrawmax))
        self.lbl_calspan.setText(str(refrawspan))
        self.lbl_volreflexlivenotes.setText("Calibration Complete")


    def appendToCalFloorSamples(self, vals):
        self._calFloorSamples.append(vals[referencesignalchannel])

    def appendToCalCeilSamples(self, vals):
        self._calCeilSamples.append(vals[referencesignalchannel])

    def startVoluntaryReflexTrial(self):
        global measzero
        global restQueue
        global refSigIsZero

        #Check Settings
        if (self._serialThread._serIsRunning == False):
            self.lbl_volreflexlivenotes.setText("Reset Serial")
            return

        if (measuredsignalchannel is None):
            self.lbl_volreflexlivenotes.setText("Set Measured Signal Channel")
            return
        if (referencesignalchannel is None):
            self.lbl_volreflexlivenotes.setText("Set Reference Signal Channel")
            return

        if (self._volreflexankleposition is None):
            self.lbl_volreflexlivenotes.setText("Set Ankle Positon")
            return

        if (volreflexflexion is None):
            self.lbl_volreflexlivenotes.setText("Set Flexion")
            return

        if (calibrationCompleteFlag == False):
            self.lbl_volreflexlivenotes.setText("Complete Calibration")
            return

        self.lbl_volreflexlivenotes.setText("")

        # Ensure channels reading correct voltage Ranges
        self._serialThread.changeVoltageRange(measuredsignalchannel, self._serialThread._voltRanges['NEG_FIVE_TO_FIVE'])
        self._serialThread.changeVoltageRange(referencesignalchannel, self._serialThread._voltRanges['ZERO_TO_FIVE'])

        # Start Writing Process
        self._serialThread.startSdWrite(self._volreflexfilename)
        self._serialThread.insertValIntoDaqReadings(7, 0)

        # Start Rest Phase
        self.lbl_volreflexlivenotes.setText("Rest Phase")
        self.restphasesamples = []
        self._serialThread.supplyDaqReadings.connect(self.appendToRestPhaseSamples)
        QtTest.QTest.qWait(5000) # 5s rest
        self._serialThread.supplyDaqReadings.disconnect()

        # Calculate a measured sig zerolevel. Its the avg of last half of rest phase samples
        nRestSamples = len(self.restphasesamples)
        measzero = int(np.mean(self.restphasesamples[int(nRestSamples/2):]))

        # Start trial cycles.  Each cycle will have a 2 sec period where the patient
        # holds within 10% of 30% MVC range, followed by a random 0-1s pause, followed by a cycle
        if (refsignaltype == "sine"):
            refSigGen.ChangeFreq(refsignalfreq)
        elif (refsignaltype == "step"):
            steptime = 3.0
            refSigGen.ChangeStepDuration(steptime)
        else:
            self.lbl_volreflexlivenotes.setText("Ref Signal Type Not Sine or Step")
            return

        # initialize data for holdtimer, randtimer, and cycletimer
        self.vrtimerfreq = 60 #hz, used for holdtimer, randtimer, cmdsigtimer
        self.holdtimer = QtCore.QTimer()
        self.randtimer = QtCore.QTimer()
        self.cmdsigtimer = QtCore.QTimer()
        self.holdtimer.setInterval(1/self.vrtimerfreq*1000)
        self.randtimer.setInterval(1/self.vrtimerfreq*1000)
        self.cmdsigtimer.setInterval(1/self.vrtimerfreq*1000)
        self.holdtimer.timeout.connect(self.vrholdtimerfun)
        self.randtimer.timeout.connect(self.vrrandtimerfun)
        self.cmdsigtimer.timeout.connect(self.vrcmdsigtimerfun)
        self.holdtime = 2 #sec
        self.holdcount = 0
        self.holdcountend = int(self.vrtimerfreq*self.holdtime)
        self.randcount = 0
        self.randcountend = 1000 #this will change
        self.cmdsigcount = 0
        self.cmdsigcountend = int((1/refsignalfreq)*self.vrtimerfreq)
        self.cyclecount = 0
        self.cyclecountend = 6

        self.holdtimer.start()

    def vrholdtimerfun(self):
        if (self.holdcount < self.holdcountend):
            # Copy data from queue
            data = np.array(serialQueue.queue)
            refdata = 0
            measdata = (data[:,measuredsignalchannel] - measzero)*serval2torqueNm
            holdtol = np.abs(referencevalspan*0.1)
            holdsuccess = not np.any(np.abs(measdata) > holdtol)

            if holdsuccess:
                self.holdcount = self.holdcount + 1
            else:
                self.holdcount = 0

            holdtimeremaining = self.holdtime*(1- (self.holdcount + 1)/self.holdcountend)
            holdtimestr = "Hold at 0\nTime Remaining: {:3.2f}".format(holdtimeremaining)
            self.lbl_volreflexlivenotes.setText(holdtimestr)
            self.updatePlot(refdata, np.mean(data[:, measuredsignalchannel]), True)
        else:
            self.randtime = random.uniform(0.5, 1.5)
            self.randcountend = int(self.vrtimerfreq*self.randtime)
            self.randcount = 0
            self.randtimer.start()
            self.holdtimer.stop()

    def vrrandtimerfun(self):
        if (self.randcount < self.randcountend):
            self.randcount = self.randcount + 1
            self.lbl_volreflexlivenotes.setText("Random Hold")

            data = np.array(serialQueue.queue)
            refdata = 0
            measdata = np.mean(data[:, measuredsignalchannel])
            refdataiszero = True
            self.updatePlot(refdata, measdata, refdataiszero)
        else:
            timecycle = 1/refsignalfreq
            self.cmdsigcount = 0
            self.cmdsigcountend = int(timecycle*self.vrtimefreq)
            self.cmdsigtimer.start()
            self.randtimer.stop()

    def vrcmdsigtimerfun(self):
        if (self.cmdsigcount < self.cmdsigcountend):
            self.cmdsigcount = self.cmdsigcount + 1
            self.lbl_volreflexlivenotes.setText("Match Reference Line")

            data = np.array(serialQueue.queue)
            refdata = np.mean(data[:, referencesignalchannel])
            measdata = np.mean(data[:, measuredsignalchannel])
            refdataiszero = False

            self.updatePlot(refdata, measdata, refdataiszero)

        else:
            self.cyclecount = self.cyclecount + 1
            self.cyclecountend = 6
            if (self.cyclecount < self.cyclecountend):
                self.holdcount = 0
                self.holdtimer.start()
                self.cmdsigtimer.stop()
            else:
                self.cmdsigtimer.stop()
                self.lbl_volreflexlivenotes.setText("Done")
                self.updatePlot(0, 0, True)



    #############################################################################
        # refSigIsZero = True
        # self._serialThread.supplyDaqReadings.connect(self.updatePlot())
        # restperiod = 2 # seconds
        # restTol = np.abs(refplotrange*0.1)
        # nCycles = 6
        # for iCycle in range(0, nCycles):
        #     # Wait until all values in restQueue are within 10% of 30% MVC
        #     restQueue = maxrefplotval*np.ones(self._serialThread._serialGetFreq*restperiod)
        #     self._serialThread.supplyDaqReadings.connect(self.cycleRestQueue())
        #     while True:
        #         QtTest.QTest.qWait(1/self._serialThread._serialGetFreq*1000)
        #         if not np.any(np.abs(restQueue) > restTol):
        #             self._serialThread.supplyDaqReadings.disconnect(self.cycleRestQueue())
        #             break
        #         else:
        #             self.lbl_volreflexlivenotes.setText("Hold 0 +/- {}".format(restTol))
        #
        #     # Random Pause Between 0 - 1 seconds
        #     self.lbl_volreflexlivenotes.setText("Random Pause")
        #     randtime = random.uniform(0.0, 1.0)
        #     sec2ms = 1000
        #     QtTest.QTest.qWait(int(randtime*sec2ms))
        #
        #
        #     # Cycle
        #     refSigIsZero = False
        #     self._serialThread.insertValIntoDaqReadings(7, iCycle+1) #insert flag
        #     if (refsignaltype == "sine"):
        #         refSigGen.GenerateUnidirectionFlex()
        #         cycletime = 1.0/refsignalfreq
        #         QtTest.QTest.qWait(int(cycletime*sec2ms))
        #     elif (refsignaltype == "step"):
        #         refSigGen.GenerateStep()
        #         QtTest.QTest.qWait(int(steptime*sec2ms))
        #     refSigIsZero = True
        #
        #     # Update progressbar
        #     progressbarval = round((iCycle + 1)/nCycles*100)
        #     self.prog_volreflextrial.setValue(progressbarval)
        #     self.prog_volreflextrial.update()
        #
        # self._serialThread.supplyDaqReadings.disconnect(self.updatePlot())

    def cycleRestQueue(self, vals):
        global restQueue
        restQueue[:-1] = restQueue[1:]
        restQueue = (vals[measuredsignalchannel]-zerolevel)*serval2torqueNm

    def appendToRestPhaseSamples(self, vals):
        self.restphasesamples.append(vals[measuredsignalchannel])


    def updatePlot(self, refdata, measdata, refsigiszero):
        # Convert Ref Sig to N-m
        if (refSigIsZero == True):
            referenceval = 0
        else:
            referenceval = refdata
            if refsignaltype == "sine":
                if volreflexflexion in ["DF", "DFPF"]:
                    referenceval = minreferenceval + ((referenceval - refrawmin)/refrawspan)*referencevalspan  # this assumes A/D measurements from the 12-bit DAQ
                elif volreflexflexion == "PF":
                    referenceval = maxreferenceval - ((referenceval - refrawmin)/refrawspan)*referencevalspan  # this assumes A/D measurements from the 12-bit DAQ
            elif refsignaltype == "step":
                if volreflexflexion ==  "DF":
                    if referenceval < 2048:
                        referenceval = minreferenceval
                    else:
                        referenceval = maxreferenceval
                elif volreflexflexion == "PF":
                    if referenceval < 2048:
                        referenceval = maxreferenceval
                    else:
                        referenceval = minreferenceval

        # Convert Meas Sig to N-m
        measuredval = (measdata - measzero) * serval2torqueNm

        #Update Plot
        self.reference_line.setData(x=np.array([0,1]),
                                    y=np.array([referenceval, referenceval]))
        self.measured_line.setData(x=np.array([0,1]),
                                   y=np.array([measuredval, measuredval]))
        self.plt.update()

    def printToVolReflexLabel(self, inputStr):
        self.lbl_volreflexlivenotes.setText(inputStr)

    def connectButtonsInSetupTab(self):
        self.btn_selectdaqport.clicked.connect(self.selectDaqPort)
        self.btn_refreshcomlist.clicked.connect(self.refreshComPortList)
        self.btn_selectreferencesignal.clicked.connect(self.selectReferenceSignalChannel)
        self.btn_selectmeasuredsignal.clicked.connect(self.selectMeasuredSignalChannel)
        self.btn_setpatientnumber.clicked.connect(self.setPatientNumber)
        self.btn_resetserial.clicked.connect(self.resetSerialOnThread)
        self.btn_startmvctrial.clicked.connect(self.startMvcTrial)
        self.btn_startvolreflextrial.clicked.connect(self.startVoluntaryReflexTrial)
        self.btn_minimize.clicked.connect(self.minimizeWindow)
        self.btn_maximize.clicked.connect(self.maximizeWindow)
        self.btn_close.clicked.connect(self.closeWindow)
        self.btn_setmvcmanual.clicked.connect(self.setmvcmanual)
        self.btn_calibrate.clicked.connect(self.calibraterefsignal)
        self.btn_prevtrial.clicked.connect(self.setTrialPrev)
        self.btn_nexttrial.clicked.connect(self.setTrialNext)


    def setTrialPrev(self):
        if self._autotrialcounter == self._autotrialcountermin:
            return
        else:
            self._autotrialcounter = self._autotrialcounter - 1
            self._autotrialround = int(self._autotrialcounter/self._trialsperround) + 1
            self._autotrialnumber = self._autotrialcounter%self._trialsperround + 1

            self.setAutoTrialLabels()
            self.setAutoTrialManualButtons()

    def setDefaultAutoTrial(self):
        self.setAutoTrialFlexFreq()
        self.setAutoTrialLabels()
        self.rbtn_volreflex0.setChecked(True)
        self.rbtn_volreflex0.click()
        self.setAutoTrialManualButtons()
        self.disableManualTrialSettings()

    def setAutoTrialManualButtons(self):
        self.enableAutoTrialSettings()
        self.enableManualTrialSettings()

        #Set flexion
        if self._autotrialflexion == "DF":
            flex_btn = self.rbtn_volreflexdf
        elif self._autotrialflexion == "PF":
            flex_btn = self.rbtn_volreflexpf
        flex_btn.setChecked(True)
        flex_btn.click()

        #Set Sine Freq
        tol = 1e-4
        if (self._autotrialsinefreq - 0.20) < tol:
            freq_btn = self.rbtn_refsig1
        elif (self._autotrialsinefreq - 0.40) < tol:
            freq_btn = self.rbtn_refsig2
        elif (self._autotrialsinefreq - 0.60) < tol:
            freq_btn = self.rbtn_refsig3
        elif (self._autotrialsinefreq - 0.80) < tol:
            freq_btn = self.rbtn_refsig4
        elif (self._autotrialsinefreq - 1.00) < tol:
            freq_btn = self.rbtn_refsig5
        elif (self._autotrialsinefreq - 1.20) < tol:
            freq_btn = self.rbtn_refsig6
        elif (self._autotrialsinefreq - 1.40) < tol:
            freq_btn = self.rbtn_refsig7
        elif (self._autotrialsinefreq - 1.60) < tol:
            freq_btn = self.rbtn_refsig8
        elif (self._autotrialsinefreq - 1.80) < tol:
            freq_btn = self.rbtn_refsig9
        elif (self._autotrialsinefreq - 2.00) < tol:
            freq_btn = self.rbtn_refsig10
        freq_btn.setChecked(True)
        freq_btn.click()

        # Set Round Number
        self.spinboxtrialnumber.setValue(self._autotrialround)

        #Disable Manual buttons
        self.disableManualTrialSettings()

    def setAutoTrialLabels(self):
            self.label_round.setText(str(self._autotrialround))
            self.label_trial.setText(str(self._autotrialnumber))
            self.setAutoTrialFlexFreq()
            self.label_trialname.setText("{} --- {:.2f} Hz".format(self._autotrialflexion, self._autotrialsinefreq))

    def setTrialNext(self):
        if self._autotrialcounter == self._autotrialcountermax:
            return
        else:
            self._autotrialcounter = self._autotrialcounter + 1
            self._autotrialround = int(self._autotrialcounter/self._trialsperround) + 1
            self._autotrialnumber = self._autotrialcounter%self._trialsperround + 1

            self.setAutoTrialLabels()
            self.setAutoTrialManualButtons()

    def setmvcmanual(self):
        mvctable['df'] = float(self.lineedit_dfmvcman.text())
        mvctable['pf'] = float(self.lineedit_pfmvcman.text())
        self.tablewidget_mvc.setItem(0, 0, QTableWidgetItem(str(round(mvctable['pf'],2))))
        self.tablewidget_mvc.setItem(0, 1, QTableWidgetItem(str(round(mvctable['df'],2))))
        self.setDfPfMvc()

    def startSettingsTab(self):

        # Complete GUI Programming
        self.customizeSetupTab()
        self.customizeVoluntaryReflexMeasurementTab()

        # Init Settings Tab Lists
        self.refreshComPortList()
        self.initReferenceSignalList()
        self.initMeasuredSignalList()

        # Connect buttons
        self.connectButtonsInSetupTab()

        # Set Auto Trial Buttons as default
        self.setDefaultAutoTrial()



if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    sys.exit(app.exec_())
