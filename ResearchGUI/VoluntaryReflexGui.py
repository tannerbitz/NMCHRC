#!/usr/bin/python3

import sys
from PyQt5.QtWidgets import *
from PyQt5 import QtCore, QtGui, QtWidgets, uic
import serial.tools.list_ports
import pyqtgraph as pg
import numpy as np
import serial

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

    def customizeSetupTab(self):
        # Expand table widget column
        self.tablewidget_mvc.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)

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

    def connectButtonsInSetupTab(self):
        self.btn_selectcomport.clicked.connect(self.selectComPort)
        self.btn_refreshcomlist.clicked.connect(self.refreshComPortList)
        self.btn_selectreferencesignal.clicked.connect(self.selectReferenceSignalChannel)
        self.btn_selectmeasuredsignal.clicked.connect(self.selectMeasuredSignalChannel)
        self.btn_setpatientnumber.clicked.connect(self.setPatientNumber)
        self.btn_resetserial.clicked.connect(self.resetSerial)



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
