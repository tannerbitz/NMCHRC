#!/usr/bin/python3

import sys
from PyQt5.QtWidgets import *
from PyQt5 import QtCore, QtGui, QtWidgets, uic
import serial.tools.list_ports
import pyqtgraph as pg
import numpy as np
import serial
import datetime
import time

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




class MainWindow(QtWidgets.QMainWindow):

    # Class Data

    # Serial Object
    _ser = None
    _serialbaudrate = 115200
    _serialtimeout = 1

    # Setting Data
    _patientnumber = None
    _referencesignalchannel = None
    _measuredsignalchannel = None
    _comport = None
    _serialstatus = None

    # MVC Trial Data
    _mvctrialflexion = None
    _mvctrialfilename = None
    _mvctable = {'pf': None, 'df': None}
    _mvcfiletoimport = None
    _mvctrialcounter = 0
    _mvctrialrepetition = 0
    _mvctimer = None

    # MVC import
    _mvcdffile = None
    _mvcpffile = None

    #Conversion Constants
    _serval2torqueNm = (125.0/2048.0)*(4.44822/1.0)*(0.15) #(125lbs/2048points)*(4.44822N/1lbs)*(0.15m)

    # Voluntary Reflex Trial data
    _volreflexankleposition = None
    _volreflexflexion = None
    _volreflexfilename = None

    def __init__(self):
        super(MainWindow, self).__init__()
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
    def selectComPort(self):
        portobj = self.list_comport.selectedItems()
        for i in list(portobj):
            selectedport = str(i.text())
        selectedportparts = selectedport.split(" ")
        self._comport = selectedportparts[0]
        self.lbl_comport.setText(self._comport)

    def selectReferenceSignalChannel(self):
        channelobj = self.list_referencesignal.selectedItems()
        for i in list(channelobj):
            selectedchannel = str(i.text())
        selectedchannelparts = selectedchannel.split(" ")
        self._referencesignalchannel = int(selectedchannelparts[1])
        self.lbl_referencesignal.setText("Channel {}".format(self._referencesignalchannel))

    def selectMeasuredSignalChannel(self):
        channelobj = self.list_measuredsignal.selectedItems()
        for i in list(channelobj):
            selectedchannel = str(i.text())
        selectedchannelparts = selectedchannel.split(" ")
        self._measuredsignalchannel = int(selectedchannelparts[1])
        self.lbl_measuredsignal.setText("Channel {}".format(self._measuredsignalchannel))

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
        if (self._comport is None):
            self.lbl_serialstatus.setText("Select COM Port")
        elif ((self._comport is not None) and (isinstance(self._ser, serial.Serial))):
            try:
                self._ser.close()
                self._ser = serial.Serial(port=self._comport, baudrate=self._serialbaudrate, timeout=self._serialtimeout)
                self.lbl_serialstatus.setText("Connected")
            except serial.SerialException as e:
                self.lbl_serialstatus.setText("Error Connecting")
        elif ((self._comport is not None) and (not isinstance(self._ser, serial.Serial))):
            try:
                self._ser = serial.Serial(port=self._comport, baudrate=self._serialbaudrate, timeout=self._serialtimeout)
                self.lbl_serialstatus.setText("Connected")
            except serial.SerialException as e:
                self.lbl_serialstatus.setText("Error Connecting")

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

    def getSerialResponse(self):
        endtime = time.time() + 0.5
        serialstring = ""
        while (time.time() < endtime):
            newchar = self._ser.read().decode()
            serialstring += newchar
            if (newchar == '>'):
                break
        return serialstring.strip('<>')


    def startMvcTrial(self):
        # Exit routine if settings aren't complete
        if (self.lbl_mvcmeasurementfilename.text() == "Complete Settings"):
            self.lbl_mvctriallivenotes.setText("Complete Settings")
            return

        # Check if serial is connected
        if self._ser is None:
            self.lbl_mvctriallivenotes.setText("Connect Serial Before Proceeding")
            return
        elif isinstance(self._ser, serial.Serial):
            self._ser.flushInput()
            self._ser.write(b'<8>')
            serialstring = self.getSerialResponse()
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
        self._ser.write(b'<6,6,0>')  # Insert Value into 6th channel of daq reading for post-process flag
        n = datetime.datetime.now()
        startStr = "<0,{},{},{},{},{},{},{}".format(self._mvctrialfilename, n.year, n.month, n.day, n.hour, n.minute, n.second)
        bStartStr = str.encode(startStr)
        self._ser.write(bStartStr)
        serialstring = self.getSerialResponse()
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
            self._ser.write(b'<6,6,0>')
            self.lbl_mvctriallivenotes.setText("Flex in {}".format(firstrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstrestend and self._mvctrialcounter < firstflexend):
            self._ser.write(b'<6,6,1>')
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(firstflexend - self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstflexend and self._mvctrialcounter < secondrestend):
            self._ser.write(b'<6,6,0>')
            self.lbl_mvctriallivenotes.setText("Rest.  Flex in {}".format(secondrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= secondrestend and self._mvctrialcounter < secondflexend):
            self._ser.write(b'<6,6,1>')
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(secondflexend - self._mvctrialcounter))
        elif (self._mvctrialcounter >= secondflexend and self._mvctrialcounter < thirdrestend):
            self._ser.write(b'<6,6,0>')
            self.lbl_mvctriallivenotes.setText("Rest.  Flex in {}".format(thirdrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= thirdrestend and self._mvctrialcounter < thirdflexend):
            self._ser.write(b'<6,6,1>')
            self.lbl_mvctriallivenotes.setText("Goooo!!! {}".format(thirdflexend - self._mvctrialcounter))
        else:
            self._ser.write(b'<1>')
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
        if self._measuredsignalchannel is None:
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
            measuredsigdata = tempdata[:, self._measuredsignalchannel]
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
                self._mvctable['pf'] = mvcserialval*self._serval2torqueNm
                self.tablewidget_mvc.setItem(0, 0, QTableWidgetItem(str(round(self._mvctable['pf'],2))))
            elif (tempflexion == 'PF'):
                mvcserialval = abs(min(mvcserialvals))
                self._mvctable['df'] = mvcserialval*self._serval2torqueNm
                self.tablewidget_mvc.setItem(0, 1, QTableWidgetItem(str(round(self._mvctable['df'],2))))


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
        self.target_line = pg.PlotCurveItem()
        self.curr_tor_line = pg.PlotCurveItem()
        self.zero_line = pg.PlotCurveItem()

        # Define line properties and set properties
        target_pen = pg.mkPen(color='c', width=30, style=QtCore.Qt.SolidLine)
        curr_tor_pen = pg.mkPen(color='r', width=10, style=QtCore.Qt.SolidLine)
        zero_line_pen = pg.mkPen(color='k', width=5, style=QtCore.Qt.DashLine)

        self.curr_tor_line.setPen(curr_tor_pen)
        self.zero_line.setPen(zero_line_pen)
        self.target_line.setPen(target_pen)

        # Set lines in initial position
        xdata = np.array([0, 1])
        ydata = np.array([0, 0])
        self.target_line.setData(x=xdata, y=ydata)
        self.curr_tor_line.setData(x=xdata, y=ydata)
        self.zero_line.setData(x=xdata, y=ydata)

        # Add lines to plot
        self.plt.addItem(self.target_line)
        self.plt.addItem(self.curr_tor_line)
        self.plt.addItem(self.zero_line)

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
        self.volreflexflexionbuttongroup.buttonClicked.connect(self.setVoluntaryReflexFlexion)

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
            self._volreflexflexion = None
        self.completeVoluntaryReflexFilename()

    def setVoluntaryReflexFlexion(self, btn_volreflexflexion):
        tempFlexion = btn_volreflexflexion.text()
        if ( tempFlexion == "Plantarflexion" ):
            self._volreflexflexion = "PF"
        elif (tempFlexion == "Dorsiflexion" ):
            self._volreflexflexion = "DF"
        else:
            self._volreflexflexion = None
        self.completeVoluntaryReflexFilename()

    def completeVoluntaryReflexFilename(self):
        # Check if Ankle Position, Flexion and Patient Number are set. If not, exit routine
        if (self._volreflexankleposition is None or self._volreflexflexion is None or self._patientnumber is None):
            self.lbl_volreflexfilename.setText("Complete Settings")
            return

        self._volreflexfilename = "Patent{}_VolReflex_AnklePos{}_{}.txt".format(self._patientnumber, self._volreflexankleposition, self._volreflexflexion)
        self.lbl_volreflexfilename.setText(self._volreflexfilename)

    def startVoluntaryReflexTrail(self):
        self.lbl_volreflexlivenotes.setText("Trial Started")
        self.prog_volreflextrial.setValue(100)

    def connectButtonsInSetupTab(self):
        self.btn_selectcomport.clicked.connect(self.selectComPort)
        self.btn_refreshcomlist.clicked.connect(self.refreshComPortList)
        self.btn_selectreferencesignal.clicked.connect(self.selectReferenceSignalChannel)
        self.btn_selectmeasuredsignal.clicked.connect(self.selectMeasuredSignalChannel)
        self.btn_setpatientnumber.clicked.connect(self.setPatientNumber)
        self.btn_resetserial.clicked.connect(self.resetSerial)
        self.btn_startmvctrial.clicked.connect(self.startMvcTrial)
        self.btn_setmvcmanual.clicked.connect(self.getMvcFile)
        self.btn_importmvcfiles.clicked.connect(self.importMvcFiles)
        self.btn_startvolreflextrial.clicked.connect(self.startVoluntaryReflexTrail)

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

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    sys.exit(app.exec_())
