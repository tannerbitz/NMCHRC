#!/usr/bin/python3

import sys
from PyQt5.QtWidgets import *
from PyQt5 import QtCore, QtGui, QtWidgets, uic
from PyQt5.QtCore import QThread, pyqtSignal
import serial.tools.list_ports
import pyqtgraph as pg
import numpy as np
import serial
import datetime
import time
from collections import deque
import random
import requests

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
ser = None
serialbaudrate = 115200
serialtimeout = 1
serval2torqueNm = (125.0/2048.0)*(4.44822/1.0)*(0.15) #(125lbs/2048points)*(4.44822N/1lbs)*(0.15m)

# Ref Signal Generator (NodeMcu)
ip_add = "192.168.0.107"

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


def getSerialResponse():
    global ser
    endtime = time.time() + 0.5
    serialstring = ""
    while (time.time() < endtime):
        newchar = ser.read().decode()
        serialstring += newchar
        if (newchar == '>'):
            break
    return serialstring.strip('<>')


class VolReflexTrialThread(QThread):
    supplyDaqReadings = pyqtSignal(float, float, float)
    printToVolReflexLabel = pyqtSignal(str)

    def __init__(self):
        QThread.__init__(self)

    def getMeasRefSignals(self):
        global measuredsignalchannel
        global referencesignalchannel
        global serialvals
        ser.write(b'<2>')
        serialstring = getSerialResponse()
        serialvals = serialstring.split(',')
        measuredval = int(serialvals[measuredsignalchannel])
        referenceval = int(serialvals[referencesignalchannel])
        return [referenceval, measuredval]

    def getMinMaxRefLevels(self):
        if (volreflexflexion == "DF"):
            maxreferenceval = percentmvc*mvctable['df']
            minreferenceval = 0
        elif (volreflexflexion == "PF"):
            maxreferenceval = 0
            minreferenceval = -(percentmvc*mvctable['pf'])
        elif (volreflexflexion == "DFPF"):
            maxreferenceval = percentmvc*mvctable['dfpf']
            minreferenceval = -maxreferenceval

        referencevalspan = maxreferenceval - minreferenceval
        return [minreferenceval, maxreferenceval, referencevalspan]

    def waitForNewZeroLevel(self):
        whatever = 0

    def standardRun(self):
        global topborder
        global bottomborder
        global refsignaltype
        global refsignalfreq
        global serialvals
        self.printToVolReflexLabel.emit("Rest Phase")
        starttime = time.time()
        zeroduration = 5
        zerocount = 0
        zerolevel = 0
        endtime = starttime + zeroduration
        while (time.time() < endtime):
            [referenceval, measuredval] = self.getMeasRefSignals()
            zerocount = zerocount + 1
            zerolevel = zerolevel + (measuredval - zerolevel)/zerocount
            progressbarval = round(100*(time.time() - starttime)/zeroduration)
            self.supplyDaqReadings.emit(0, 0, progressbarval)

        zerolevel = int(zerolevel)
        measuredvalqueue = deque([0, 0, 0])
        [minreferenceval, maxreferenceval, referencevalspan] = self.getMinMaxRefLevels()
        starttime = time.time()
        self.printToVolReflexLabel.emit("Match the Reference Line")


        if (refsignaltype in ['prbs']):   #PRBS input
            trialduration = 60
            endtime = starttime + trialduration
            while (time.time() < endtime):
                [referenceval, measuredval] = self.getMeasRefSignals()
                measuredvalqueue.popleft()
                measuredvalqueue.append(serval2torqueNm*(measuredval - zerolevel))
                measuredval = np.mean(measuredvalqueue)
                referenceval = int(serialvals[referencesignalchannel])
                if (measuredval < bottomborder):
                    measuredval = bottomborder
                elif (measuredval > topborder):
                    measuredval = topborder

                if (referenceval > 2048):   #high input
                    referenceval = maxreferenceval
                else:                       #low input
                    referenceval = minreferenceval

                progressbarval = round(100*(time.time() - starttime)/trialduration)
                referenceval = minreferenceval + (referenceval/4095)*referencevalspan  # this assumes A/D measurements from the 12-bit DAQ
                self.supplyDaqReadings.emit(measuredval, referenceval, progressbarval)

        elif (refsignaltype in ['sine', 'step']):
            numcycles = 6
            if refsignaltype == "step":
                steptime = 3.0
                changesteptimeurl = "http://" + ip_add + "/ChangeStepTime?T=" + str(steptime)
                requests.get(changesteptimeurl)


            for icycle in range(0, numcycles):
                randtime = random.uniform(4.0, 6.0)
                starttime_rand = time.time()
                endtime_rand = starttime_rand + randtime
                starttime_cycle = endtime_rand
                if refsignaltype == "sine":
                    endtime_cycle = starttime_cycle + 1/refsignalfreq
                elif refsignaltype == "step":
                    endtime_cycle = starttime_cycle + steptime

                # Random Time Between Cycles
                while (time.time() < endtime_rand):
                    [referenceval, measuredval] = self.getMeasRefSignals()
                    measuredvalqueue.popleft()
                    measuredvalqueue.append(serval2torqueNm*(measuredval - zerolevel))
                    measuredval = np.mean(measuredvalqueue)
                    referenceval = int(serialvals[referencesignalchannel])
                    if (measuredval < bottomborder):
                        measuredval = bottomborder
                    elif (measuredval > topborder):
                        measuredval = topborder

                    progressbarval = round((icycle)/numcycles*100)
                    referenceval = 0
                    self.supplyDaqReadings.emit(measuredval, referenceval, progressbarval)

                # Trigger reference signal generator (Due) to output a sine cycle
                if refsignaltype == "sine":
                    if volreflexflexion in ["DF", "PF"]:
                        newcycleaddress = "http://" + ip_add + "/NewCycleUni"
                    elif volreflexflexion in ["DFPF"]:
                        newcycleaddress = "http://" + ip_add + "/NewCycleMulti"
                elif refsignaltype == "step":
                    newcycleaddress = "http://" + ip_add + "/NewCycleStep"
                requests.get(newcycleaddress)
                # Cycle Time
                while (time.time() < endtime_cycle):
                    [referenceval, measuredval] = self.getMeasRefSignals()
                    measuredvalqueue.popleft()
                    measuredvalqueue.append(serval2torqueNm*(measuredval - zerolevel))
                    measuredval = np.mean(measuredvalqueue)
                    referenceval = int(serialvals[referencesignalchannel])
                    if (measuredval < bottomborder):
                        measuredval = bottomborder
                    elif (measuredval > topborder):
                        measuredval = topborder

                    progressbarval = round((icycle + 1)/numcycles*100)
                    if refsignaltype == "sine":
                        if volreflexflexion in ["DF", "DFPF"]:
                            referenceval = minreferenceval + (referenceval/4095)*referencevalspan  # this assumes A/D measurements from the 12-bit DAQ
                        elif volreflexflexion == "PF":
                            referenceval = maxreferenceval - (referenceval/4095)*referencevalspan  # this assumes A/D measurements from the 12-bit DAQ
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
                    self.supplyDaqReadings.emit(measuredval, referenceval, progressbarval)

            #Extra 3 seconds of padding
            endtime = time.time() + 3
            while (time.time() < endtime):
                [referenceval, measuredval] = self.getMeasRefSignals()
                measuredvalqueue.popleft()
                measuredvalqueue.append(serval2torqueNm*(measuredval - zerolevel))
                measuredval = np.mean(measuredvalqueue)
                referenceval = int(serialvals[referencesignalchannel])
                if (measuredval < bottomborder):
                    measuredval = bottomborder
                elif (measuredval > topborder):
                    measuredval = topborder

                progressbarval = round((icycle + 1)/numcycles*100)
                referenceval = 0
                self.supplyDaqReadings.emit(measuredval, referenceval, progressbarval)

        self.supplyDaqReadings.emit(0,0,0)
        self.printToVolReflexLabel.emit("Done")
        ser.write(b'<1>')


    def run(self):
        global refsignaltype
        self.standardRun()


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

    def resetSerial(self):
        global ser
        if (self._daqport is None):
            self.lbl_daqportstatus.setText("Select COM Port")
        elif ((self._daqport is not None) and (isinstance(ser, serial.Serial))):
            try:
                ser.close()
                ser = serial.Serial(port=self._daqport, baudrate=serialbaudrate, timeout=serialtimeout)
                self.lbl_daqportstatus.setText("Connected")
            except serial.SerialException as e:
                self.lbl_daqportstatus.setText("Error Connecting")
        elif ((self._daqport is not None) and (not isinstance(ser, serial.Serial))):
            try:
                ser = serial.Serial(port=self._daqport, baudrate=serialbaudrate, timeout=serialtimeout)
                self.lbl_daqportstatus.setText("Connected")
            except serial.SerialException as e:
                self.lbl_daqportstatus.setText("Error Connecting")

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
        global ser
        # Exit routine if settings aren't complete
        if (self.lbl_mvcmeasurementfilename.text() == "Complete Settings"):
            self.lbl_mvctriallivenotes.setText("Complete Settings")
            return

        # Check if serial is connected
        if ser is None:
            self.lbl_mvctriallivenotes.setText("Connect Serial Before Proceeding")
            return
        elif isinstance(ser, serial.Serial):
            ser.flushInput()
            ser.write(b'<8>')
            serialstring = getSerialResponse()
            # Check if sd card is inserted
            if (serialstring == "False"):
                self.lbl_mvctriallivenotes.setText("Insert SD Card")
                return
            elif (serialstring == ""):
                self.lbl_mvctriallivenotes.setText("No SD Card Response")
                return
        else:
            self.lbl_mvctriallivenotes.setText("Something has gone very badly...")
            return

        # Start Writing Process
        ser.write(b'<6,6,0>')  # Insert Value into 6th channel of daq reading for post-process flag
        n = datetime.datetime.now()
        startStr = "<0,{},{},{},{},{},{},{}>".format(self._mvctrialfilename, n.year, n.month, n.day, n.hour, n.minute, n.second)
        bStartStr = str.encode(startStr)
        ser.write(bStartStr)
        serialstring = getSerialResponse()
        if (len(serialstring) != 0):  # This would happen if there was an unexpected error with the DAQ
            self.lbl_mvctriallivenotes.setText(serialstring)
            return

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
        if (self._mvctrialcounter < firstrestend):
            ser.write(b'<6,6,0>')
            self.lbl_mvctriallivenotes.setText("Flex in {}".format(firstrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstrestend and self._mvctrialcounter < firstflexend):
            ser.write(b'<6,6,1>')
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(firstflexend - self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstflexend and self._mvctrialcounter < secondrestend):
            ser.write(b'<6,6,0>')
            self.lbl_mvctriallivenotes.setText("Rest.  Flex in {}".format(secondrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= secondrestend and self._mvctrialcounter < secondflexend):
            ser.write(b'<6,6,1>')
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(secondflexend - self._mvctrialcounter))
        elif (self._mvctrialcounter >= secondflexend and self._mvctrialcounter < thirdrestend):
            ser.write(b'<6,6,0>')
            self.lbl_mvctriallivenotes.setText("Rest.  Flex in {}".format(thirdrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= thirdrestend and self._mvctrialcounter < thirdflexend):
            ser.write(b'<6,6,1>')
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(thirdflexend - self._mvctrialcounter))
        else:
            ser.write(b'<1>')
            self.lbl_mvctriallivenotes.setText("Done")
            self._mvctimer.stop()
            self._mvctimer.deleteLater()

        self._mvctrialcounter += 1


    def getMvcFile(self):
        #Open filedialog box
        options = QFileDialog.Options()
        options |= QFileDialog.DontUseNativeDialog
        files, _ = QFileDialog.getOpenFileNames(self, "QFileDialog.getOpenFileNames()", "",
                                                "Text Files (*.txt)", options=options)
        if files:
            for f in files:
                if (f.find('MVC') == -1):
                    self.lbl_mvctriallivenotes.setText("Please Select MVC File")
                else:
                    tempfullfilepath = f
                    f = f.split('/')
                    f = f[-1] # now f is just the filename
                    tempfilename = f
                    f = f.strip('.txt')
                    f = f.split('_')
                    tempflexion = f[-1]
                    temppatientnumber = f[0]
                    temppatientnumber = int(temppatientnumber.strip("Patient"))
                    if ( temppatientnumber != self._patientnumber):
                        self.lbl_mvctriallivenotes.setText("Patient Number does not match.  Import aborted")
                    else:
                        if (tempflexion == 'DF'):
                            self._mvcdffile = tempfullfilepath
                            self.lbl_mvctriallivenotes.setText("")
                            self.lineedit_mvcmanual.setText(tempfilename)
                        elif (tempflexion == 'PF'):
                            self._mvcpffile = tempfullfilepath
                            self.lbl_mvctriallivenotes.setText("")
                            self.lineedit_mvcmanual.setText(tempfilename)
                        else:
                            self.lbl_mvctriallivenotes.setText("Filename does not specify flexion")

    def importMvcFiles(self):
        global measuredsignalchannel
        global mvctable
        if measuredsignalchannel is None:
            self.lbl_mvctriallivenotes.setText('Set Measured Signal Channel')
            return
        tempfilestoimport = []
        if self._mvcdffile is not None:
            tempfilestoimport.append(self._mvcdffile)
        if self._mvcpffile is not None:
            tempfilestoimport.append(self._mvcpffile)

        if (len(tempfilestoimport)==0):
            self.lbl_mvctriallivenotes.setText('Choose file to import')
            return

        for f in tempfilestoimport:
            if (f.find('DF') != -1):
                tempflexion = 'DF'
            elif (f.find('PF') != -1):
                tempflexion = 'PF'
            else:
                self.lbl_mvctriallivenotes.setText("Flexion direction was not found in file during import")
                return
            tempdata = np.loadtxt(fname=f, delimiter=',')
            flagcol = tempdata[:,6]
            measuredsigdata = tempdata[:, measuredsignalchannel]
            # get indices where 'rest' or 'flex' periods end
            rest_flex_ending_indices = [0]
            currentflag = flagcol[0]
            for i in range(1, len(flagcol)):
                if (flagcol[i] != currentflag):
                    currentflag = flagcol[i]
                    rest_flex_ending_indices.append(i)
                elif (i==(len(flagcol)-1)):
                    rest_flex_ending_indices.append(i+1)
            for i in range(1, len(rest_flex_ending_indices)):
                if ((rest_flex_ending_indices[i] - rest_flex_ending_indices[i-1]) < 4000):
                    self.lbl_mvctriallivenotes.setText("Rest or flex period was less than 4000 readings. Check data")
                    return
            mvcserialvals = []
            for i in range(0,3):
                restbeginindex = rest_flex_ending_indices[i*2]
                restendindex = rest_flex_ending_indices[i*2 + 1]
                flexbeginindex = rest_flex_ending_indices[i*2 + 1]
                flexendindex = rest_flex_ending_indices[i*2 + 2]
                restmeasurements = measuredsigdata[restbeginindex+500:restendindex-500]  # limit rest measurements just in case the patient flexed early or late
                mvcmeasaurements = measuredsigdata[flexbeginindex:flexendindex]
                zerolevel = int(restmeasurements.mean())
                if (tempflexion == 'DF'):
                    mvcserialvals.append(int(mvcmeasaurements.max() - zerolevel))
                elif (tempflexion == 'PF'):
                    mvcserialvals.append(int(mvcmeasaurements.min() - zerolevel))

            if (tempflexion == 'DF'):
                mvcserialval = abs(max(mvcserialvals))
                mvctable['pf'] = mvcserialval*serval2torqueNm
                self.tablewidget_mvc.setItem(0, 0, QTableWidgetItem(str(round(mvctable['pf'],2))))
            elif (tempflexion == 'PF'):
                mvcserialval = abs(min(mvcserialvals))
                mvctable['df'] = mvcserialval*serval2torqueNm
                self.tablewidget_mvc.setItem(0, 1, QTableWidgetItem(str(round(mvctable['df'],2))))
            self.setDfPfMvc()

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
            changefreqadd = "http://" + ip_add + "/ChangeFreq?Freq=" + freqtext
            requests.get(changefreqadd)

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
        tempFlexion = btn_volreflexflexion.text()
        if ( tempFlexion == "Plantarflexion" ):
            volreflexflexion = "PF"
            if (mvctable['pf'] is None):
                self.lbl_volreflexlivenotes.setText('Import PF MVC Trial Readings')
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
        global ser
        # Exit routine if settings aren't complete
        if (self.lbl_mvcmeasurementfilename.text() == "Complete Settings"):
            self.lbl_volreflexlivenotes.setText("Complete Settings")
            return

        # Check if serial is connected
        if ser is None:
            self.lbl_volreflexlivenotes.setText("Connect Serial")
            return
        elif isinstance(ser, serial.Serial):
            ser.flushInput()
            ser.write(b'<8>')
            serialstring = getSerialResponse()
            # Check if sd card is inserted
            if (serialstring == "False"):
                self.lbl_volreflexlivenotes.setText("Insert SD Card")
                return
            elif (serialstring == ""):
                self.lbl_volreflexlivenotes.setText("No SD Card Response")
                return
        else:
            self.lbl_volreflexlivenotes.setText("Something has gone very badly...")
            return

        serialstring = getSerialResponse()
        if (len(serialstring) != 0):  # This would happen if there was an unexpected error with the DAQ
            self.lbl_mvctriallivenotes.setText(serialstring)
            return


        #Trigger Calibration Signal from Ref Signal Generator
        calibrationurl = "http://" + ip_add + "/Calibrate"
        requests.get(calibrationurl)

        global calibrationReferenceMeasurements
        calibrationReferenceMeasurements = []
        self._calibrationtimercounter = 0
        self._calibrationtimer = QtCore.QTimer()
        self._calibrationtimer.timeout.connect(self.completeCalibration)
        self._calibrationtimer.start(2)

    def completeCalibration(self):
        global calibrationReferenceMeasurements
        self._calibrationtimercounter += 1
        if (self._calibrationtimercounter < 500):
            [refval, measval] = getMeasRefSignals()
            calibrationReferenceMeasurements.append(refval)
        else:
            refmin = min(calibrationReferenceMeasurements)
            refmax = max(calibrationReferenceMeasurements)
            refspan = refmax - refmin
            self.lbl_calmin.setText(str(refmin))
            self.lbl_calmax.setText(str(refmax))
            self.lbl_calspan.setText(str(refspan))
            self.lbl_volreflexlivenotes.setText("Calibration Complete")
            self._calibrationtimercounter.stop()
            self._calibrationtimercounter.deleteLater()

    def startVoluntaryReflexTrail(self):
        global ser
        global measuredsignalchannel
        global referencesignalchannel
        #Check Settings
        if (self._volreflextrialthread.isRunning()):
            self.lbl_volreflexlivenotes.setText("Thread Is Already Running")
            return
        self.lbl_volreflexlivenotes.setText("")
        if (measuredsignalchannel is None):
            self.lbl_volreflexlivenotes.setText("Set Measured Signal Channel")
            return
        if (referencesignalchannel is None):
            self.lbl_volreflexlivenotes.setText("Set Reference Signal Channel")
            return
        if not (isinstance(ser, serial.Serial)):
            self.lbl_volreflexlivenotes.setText("Connect DAQ Device")
            return
        if (self._volreflexankleposition is None):
            self.lbl_volreflexlivenotes.setText("Set Ankle Positon")
            return
        if (volreflexflexion is None):
            self.lbl_volreflexlivenotes.setText("Set Flexion")
            return

        # Ensure channels reading correct voltage Ranges
        voltagerangecommand_measuredsignal = "<5,{},1>".format(measuredsignalchannel)   # assuems -5V to +5V readings
        voltagerangecommand_referencesignal = "<5,{},0>".format(referencesignalchannel) # assumes 0-5V readings
        ser.write(str.encode(voltagerangecommand_measuredsignal))
        ser.write(str.encode(voltagerangecommand_referencesignal))
        # Start Writing Process
        ser.write(b'<6,6,0>')  # Insert Value into 6th channel of daq reading for post-process flag
        n = datetime.datetime.now()
        startStr = "<0,{},{},{},{},{},{},{}>".format(self._volreflexfilename, n.year, n.month, n.day, n.hour, n.minute, n.second)
        bStartStr = str.encode(startStr)
        ser.write(bStartStr) #start writing to sd
        serialstring = getSerialResponse()
        if (len(serialstring) != 0):  # This would happen if there was an unexpected error with the DAQ
            self.lbl_volreflexlivenotes.setText(serialstring)
            return
        self._volreflextrialthread.start()

    def initVoluntaryReflexTrialThread(self):
        self._volreflextrialthread = VolReflexTrialThread()
        self._volreflextrialthread.printToVolReflexLabel.connect(self.printToVolReflexLabel)
        self._volreflextrialthread.supplyDaqReadings.connect(self.updateVolReflexPlot)

    def updateVolReflexPlot(self, measuredval, referenceval, progressbarval):
        #Update Progressbar
        self.prog_volreflextrial.setValue(progressbarval)
        self.prog_volreflextrial.update()

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
        self.btn_resetserial.clicked.connect(self.resetSerial)
        self.btn_startmvctrial.clicked.connect(self.startMvcTrial)
        self.btn_startvolreflextrial.clicked.connect(self.startVoluntaryReflexTrail)
        self.btn_minimize.clicked.connect(self.minimizeWindow)
        self.btn_maximize.clicked.connect(self.maximizeWindow)
        self.btn_close.clicked.connect(self.closeWindow)
        self.btn_setmvcmanual.clicked.connect(self.setmvcmanual)
        self.btn_calibrate.clicked.connect(self.calibraterefsignal)

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

        #Init Voluntary Reflex Trial Thread
        self.initVoluntaryReflexTrialThread()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    sys.exit(app.exec_())
