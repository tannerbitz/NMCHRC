#!/usr/bin/python3

import sys
from PyQt5.QtWidgets import *
from PyQt5 import QtCore, QtGui, QtWidgets, uic, QtTest
from PyQt5.QtCore import QThread, pyqtSignal
import serial.tools.list_ports
import pyqtgraph as pg
import numpy as np
import serial
from scipy import signal
import queue
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import sqlite3
import os
import datetime

# Channels
referencesignalchannel = 1
measuredsignalchannel = 0

# Serial Object
serialbaudrate = 115200
serialtimeout = 1
serval2torqueNm = (125.0/2048.0)*(4.44822/1.0)*(0.15) #(125lbs/2048points)*(4.44822N/1lbs)*(0.15m)

# Database
def create_table(conn, create_tbl_sql):
    c = conn.cursor()
    c.execute(create_tbl_sql)

def insert_into_user_table(conn, name, isAdult, mvcTrialData=np.array([]), mvc=0):
    sql_insert_into_user_table = """INSERT INTO user(name, isAdult, mvcTrialData, mvc)
                                    VALUES (?,?,?,?)"""
    try:
        c = conn.cursor()
        bMvcData = mvcTrialData.tobytes()
        c.execute(sql_insert_into_user_table, (name, isAdult, bMvcData, mvc))
        conn.commit()
        success = True
        return success
    except:
        success = False
        return success

def insert_into_target_table(conn, name, targetsHit, year):
    sql_insert_into_target_table = """ INSERT INTO target(user_name, targetsHit, year)
                                       VALUES(?, ?, ?)"""
    try:
        c = conn.cursor()
        c.execute(sql_insert_into_target_table, (name, targetsHit, year))
        conn.commit()
        success = True
        return success
    except:
        sucess = False
        return success

def update_player_record(conn, name, isAdult, mvcTrialData, mvc):
    sql_update_player = """UPDATE user
                           SET isAdult=?,
                               mvcTrialData=?,
                               mvc=?
                           WHERE name=?"""
    c = conn.cursor()
    bMvcData = mvcTrialData.tobytes()
    c.execute(sql_update_player, (isAdult, bMvcData, mvc, name))
    conn.commit()

def get_player_record(conn, name):
    sql_select_player_record = """SELECT * FROM user
                                  WHERE user.name=(?)"""
    c = conn.cursor()
    c.execute(sql_select_player_record, (name,))
    records = c.fetchall()
    return records

def get_all_player_names(conn):
    sql_select_all_player_names = """SELECT user.name FROM user"""
    c = conn.cursor()
    c.execute(sql_select_all_player_names)
    records = c.fetchall()
    names = [""]
    for record in records:
        names.append(record[0])
    return names

def get_leaderboard_records(conn, sqlstr):
    c = conn.cursor()
    c.execute(sqlstr)
    return c.fetchall()

def init_db(dbpath=None):
    if (dbpath is None):
        dbpath = os.path.join(os.getcwd(), 'ASUOpenDoorDemoDb.db')
    sql_create_table_user = """ CREATE TABLE IF NOT EXISTS user (
                            name text PRIMARY KEY,
                            isAdult int NOT NULL,
                            mvcTrialData blob,
                            mvc real
                            );
                            """
    sql_create_table_target = """ CREATE TABLE IF NOT EXISTS target (
                              id INTEGER PRIMARY KEY AUTOINCREMENT,
                              user_name text,
                              targetsHit int NOT NULL,
                              year int NOT NULL,
                              FOREIGN KEY (user_name) REFERENCES user(name)
                              );
                              """

    conn = sqlite3.connect(dbpath)
    create_table(conn, sql_create_table_user)
    create_table(conn, sql_create_table_target)
    return conn



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
    _serialstring = ""
    _recordstring = False
    _serialstringdone = False
    _serialstringstoprocess = queue.Queue()
    _sdInserted = False
    _noreadcount = 0
    _waitForSdCardInsertedResponse = 500 #0.5 sec wait default. Will be changed in init method

    # Live Data Filter
    filterOrder, filterWn = signal.buttord(wp=1/9, ws=3/9, gpass=1, gstop=20, analog=False)
    filterNum, filterDen = signal.butter(filterOrder, filterWn, btype='lowpass', analog=False, output='ba')
    refdata_live_unfiltered = np.zeros([1,filterOrder+1]).flatten()
    refdata_live_filtered = np.zeros([1,filterOrder+1]).flatten()
    measdata_live_unfiltered = np.zeros([1,filterOrder+1]).flatten()
    measdata_live_filtered = np.zeros([1,filterOrder+1]).flatten()

    def __init__(self):
        QThread.__init__(self)
        try:
            # Setup Serial Timer To Get and Emit Serial Readings. Timer not started til later.
            self._serialTimer = QtCore.QTimer()
            self._serialTimerFreq = 180.0
            self._waitForSdCardInsertedResponse = 1/self._serialTimerFreq*30*1000
            self._serialTimer.setInterval(1.0/self._serialTimerFreq*1000.0)
            self._serialTimer.timeout.connect(self.readFromDaq)
            self._serialTimer.timeout.connect(self.callForDaqReadings)
        except Exception as e:
            print(e)
            self.supplyMessage.emit("Error Occured During Timer Setup")

    def resetSerial(self, serialPort, serialBaudrate, serialTimeout):
        # Stop Timer From Getting Serial Data and Emitting It
        self._serialTimer.stop()

        # Close serial connection if it's connected
        if isinstance(self._ser, serial.Serial):
            try:
                self._ser.close()
            except Exception as e:
                print(e)
                self.supplyMessage.emit("Closing Serial Caused an Error")

        # Reconnect serial
        try:
            self._ser = serial.Serial(port=serialPort, baudrate=serialbaudrate, timeout=serialtimeout)
            self.supplyMessage.emit("Connected")
            self._serIsRunning = True
        except serial.SerialException as e:
            self.supplyMessage.emit("Serial Exception Occured")
            self._serIsRunning = False
        except Exception as e:
            print(e)
            self.supplyMessage.emit("Something Bad Happened")
            self._serIsRunning = False
            #clear buffer if anything

        # Restart Serial Timer
        if (self._serIsRunning):
            self._serialTimer.start()

    def readFromDaq(self):
        try:
            #check for err messages that arrived since last data call
            if self._ser.in_waiting:
                self._noreadcount = 0
                while self._ser.in_waiting:
                    temp = self._ser.read().decode()
                    if (temp == ">"):
                        self._recordstring = False
                        self._serialstringdone = True

                    if (self._recordstring):  # if between "<" and ">", read string
                        self._serialstring += temp

                    if (temp == "<"):
                        self._recordstring = True

                    if (self._serialstringdone):
                        self._serialstringdone = False
                        self._serialstringstoprocess.put(self._serialstring)
                        self._serialstring = ""
                        self.handleSerialStrings()

            else:
                self._noreadcount += 1
                # if it hasn't read data for a sec, assume the DAQ needs to be restarted
                if (self._noreadcount == self._serialTimerFreq):
                    raise Exception


        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except Exception as e:
            print(e)
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def callForDaqReadings(self):
        try:
            self._ser.write(b'<2>')
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except Exception as e:
            print(e)
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def handleSerialStrings(self):
        global refdata_live_filtered
        global refdata_live_unfiltered
        global measdata_live_filtered
        global measdata_live_unfiltered
        try:
            while (not self._serialstringstoprocess.empty()):
                temp = self._serialstringstoprocess.get()
                temp.strip('<>')
                temparr = temp.split(",")
                cmd = int(temparr[0])
                if (cmd == 0): #Err Message
                    self.supplyMessage.emit("Error Msg: {}".format(temparr[1]))
                elif (cmd == 1):  #DAQ Readings
                    vals = list(map(lambda x: int(x), temparr[1:]))
                    if (referencesignalchannel is not None):
                        # Filter reference signal data
                        self.refdata_live_unfiltered[1:] = self.refdata_live_unfiltered[0:-1]
                        self.refdata_live_filtered[1:] = self.refdata_live_filtered[0:-1]
                        self.refdata_live_unfiltered[0] = vals[referencesignalchannel]
                        self.refdata_live_filtered[0] = (self.filterNum.dot(self.refdata_live_unfiltered) - self.filterDen[1:].dot(self.refdata_live_filtered[1:]))/self.filterDen[0]
                    if (measuredsignalchannel is not None):
                        # Filter measured signal data
                        self.measdata_live_unfiltered[1:] = self.measdata_live_unfiltered[0:-1]
                        self.measdata_live_filtered[1:] = self.measdata_live_filtered[0:-1]
                        self.measdata_live_unfiltered[0] = vals[measuredsignalchannel]
                        self.measdata_live_filtered[0] = (self.filterNum.dot(self.measdata_live_unfiltered) - self.filterDen[1:].dot(self.measdata_live_filtered[1:]))/self.filterDen[0]
                    self.supplyDaqReadings.emit(vals)
                elif (cmd == 2): # Is SD Inserted Response
                    if temparr[1] == "True":
                        self._sdInserted = True
                    elif temparr[1] == "False":
                        self._sdInserted = False
                    else:
                        print("sd inserted gave unexpected result: {}".format(temparr[1:]))
                elif (cmd == 3): #I2C device settings response
                    print(temparr[1:])
                else:
                    print("Unexpected first command while handling serial string")
                    print("cmd: {}".format(temparr[0]))
                    print("The rest of serial string: {}".format(temparr[1:]))
        except Exception as e:
            print(e)




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
        except Exception as e:
            print(e)
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
        except Exception as e:
            print(e)
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
        except Exception as e:
            print(e)
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
        except Exception as e:
            print(e)
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
        except Exception as e:
            print(e)
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

    def isSDCardInserted(self):
        # DAQ Command to Start a Write is <8>
        bCmdStr = str.encode("<8>", 'utf-8')
        try:
            self._ser.write(bCmdStr)
        except (OSError, serial.SerialException):
            self._serialTimer.stop()
            self._serIsRunning = False
            self.supplyMessage.emit("Serial Input/Output Error Occured\nReset Serial")
        except Exception as e:
            print(e)
            self._serialTimer.stop()
            self._serIsRunning = False
            errStr = "Failure With DAQ\nCycle Power To DAQ"
            self.supplyMessage.emit(errStr)

class User:
    _name = ""
    _isAdult = False
    _mvcTrialData = np.array([])
    _mvc = 0.0


    def __init__(self, name="", isAdult=False, mvctrialrawdata=np.array([]), mvc=None, targethithist=[]):
        self._name = name
        self._mvctrialrawdata = mvctrialrawdata
        self._mvc = mvc
        self._targethithist = targethithist



class MainWindow(QtWidgets.QMainWindow):

    # Class Data

    # Setting Data
    _comport = None

    # Serial
    _serialThread = None

    # Player
    _player = User()

    # Database
    _db = init_db()

    def __init__(self):
        super(MainWindow, self).__init__()
        ag = QDesktopWidget().availableGeometry()
        self.setGeometry(0, 0, 1366, 650)
        uic.loadUi('ASUOpenDoorGUI.ui', self)
        self.show()
        self.initializeGui()

    def initializeGui(self):
        # Initialize Buttons
        self.connectButtons()

        # Get Players List on Startup
        self.refreshReturningPlayerList()

        # Inialize Leaderboard
        self.initLeaderboardRbnGroup()
        self.initLeaderboard()

    def initLeaderboard(self):
        self.table_targetleaderboard.setRowCount(1)
        self.table_targetleaderboard.setColumnCount(2)
        self.table_targetleaderboard.setHorizontalHeaderItem(0, QTableWidgetItem("Player"))
        self.table_targetleaderboard.setHorizontalHeaderItem(1, QTableWidgetItem("Targets Hit"))
        self.table_targetleaderboard.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.checkLeaderboardBtnsAndUpdate()

    def initLeaderboardRbnGroup(self):
        self.leaderboardrbtngroup = QButtonGroup(self)
        self.leaderboardrbtngroup.addButton(self.rbtn_overallleaderboard)
        self.leaderboardrbtngroup.addButton(self.rbtn_youthleaderboard)
        self.leaderboardrbtngroup.addButton(self.rbtn_adultleaderboard)
        self.leaderboardrbtngroup.buttonClicked.connect(self.updateLeaderboard)


    def connectButtons(self):
        self.btn_refreshcomlist.clicked.connect(self.refreshComPortList)
        self.btn_refreshcomlist.click()
        self.btn_selectcomport.clicked.connect(self.selectComPort)
        self.btn_resetserial.clicked.connect(self.resetSerialOnThread)
        self.btn_analyzemvc.clicked.connect(self.analyzeMvc)
        self.btn_addplayer.clicked.connect(self.addPlayer)
        self.combo_returningplayer.activated.connect(self.chooseReturningPlayer)
        self.btn_recordmvc.clicked.connect(self.recordMvc)
        self.btn_targetgamestart.clicked.connect(self.targetgamestart)

    def targetgamestart(self):
        now = datetime.datetime.now()
        insert_into_target_table(self._db,
                                 self._player._name,
                                 1,
                                 now.year)
        self.checkLeaderboardBtnsAndUpdate()


    def recordMvc(self):

        # Check If Player Name is empty
        if (self._player._name == ""):
            self.lbl_livenotes.setText("Please Set Player")
            return

        # Check if serial is connected and SD Card is inserted
        if (self._serialThread is None):
            self.lbl_livenotes.setText("Connect Serial Before Proceeding")
            return
        if (self._serialThread._serIsRunning == False or self._serialThread is None):
            self.lbl_livenotes.setText("Connect Serial Before Proceeding")
            return

        # Temporary container for measured data
        self._mvcTrialDataTemp = []
        self._serialThread.supplyDaqReadings.connect(self.insertToMvcTrialDataTemp)

        self._mvctrialcounter = 0
        self._mvctrialrepetition = 0
        self._mvctimer = QtCore.QTimer()
        self._mvctimer.timeout.connect(self.mvcTrialHandler)
        self._mvctimer.start(1000)

    def insertToMvcTrialDataTemp(self, vals):
        if measuredsignalchannel is not None:
            self._mvcTrialDataTemp.append(vals[measuredsignalchannel])

    def mvcTrialHandler(self):
        firstrestend = 5
        firstflexend = firstrestend + 3
        secondrestend = firstflexend + 5
        secondflexend = secondrestend + 3
        flexstr = "Pull"  #Dorsiflexion
        if (self._mvctrialcounter < firstrestend):
            self._serialThread.insertValIntoDaqReadings(7, 0) #insert 0 into 6th channel
            self.lbl_livenotes.setText("{} in {}".format(flexstr, firstrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstrestend and self._mvctrialcounter < firstflexend):
            self._serialThread.insertValIntoDaqReadings(7, 1) #insert 1 into 6th channel
            self.lbl_livenotes.setText("Goooo!!! {}".format(firstflexend - self._mvctrialcounter))
        elif (self._mvctrialcounter >= firstflexend and self._mvctrialcounter < secondrestend):
            self._serialThread.insertValIntoDaqReadings(7, 0)
            self.lbl_livenotes.setText("Rest.  {} in {}".format(flexstr, secondrestend-self._mvctrialcounter))
        elif (self._mvctrialcounter >= secondrestend and self._mvctrialcounter < secondflexend):
            self._serialThread.insertValIntoDaqReadings(7, 1)
            self.lbl_livenotes.setText("Goooo!!! {}".format(secondflexend - self._mvctrialcounter))
        else:
            self.lbl_livenotes.setText("Done")

            self._player._mvcTrialData = np.array(self._mvcTrialDataTemp).flatten()
            self._mvcTrialDataTemp = []
            update_player_record(self._db,
                                 self._player._name,
                                 self._player._isAdult,
                                 self._player._mvcTrialData,
                                 self._player._mvc)
            self._mvctimer.timeout.disconnect(self.mvcTrialHandler)


            self._mvctimer.stop()
            self._mvctimer.deleteLater()

        self._mvctrialcounter += 1



    def checkLeaderboardBtnsAndUpdate(self):
        rbtn = self.leaderboardrbtngroup.checkedButton()
        self.updateLeaderboard(rbtn)

    def updateLeaderboard(self, rbtn):
        now = datetime.datetime.now()

        if (rbtn.text() == "Youth"):
            filterAge = 0
            sqlstr = """SELECT target.user_name, target.targetsHit
                        FROM target INNER JOIN user ON target.user_name = user.name
                        WHERE user.isAdult={} AND target.year={} LIMIT 20
                        """.format(filterAge, now.year)
        elif (rbtn.text() == "Adult"):
            filterAge = 1
            sqlstr = """SELECT target.user_name, target.targetsHit
                        FROM target INNER JOIN user ON target.user_name = user.name
                        WHERE user.isAdult={} AND target.year={} LIMIT 20
                        """.format(filterAge, now.year)
        elif (rbtn.text() == "Overall"):
            sqlstr = """SELECT target.user_name, target.targetsHit
                        FROM target INNER JOIN user ON target.user_name = user.name
                        WHERE target.year={} LIMIT 20
                        """.format(now.year)

        records = get_leaderboard_records(self._db, sqlstr)
        nRecords = len(records)
        self.table_targetleaderboard.setRowCount(nRecords)
        count = 0
        for record in records:
            self.table_targetleaderboard.setItem(count, 0, QTableWidgetItem(str(record[0])))
            self.table_targetleaderboard.setItem(count, 1, QTableWidgetItem(str(record[1])))
            count += 1


    def chooseReturningPlayer(self, player):
        self._player._name = self.combo_returningplayer.itemText(player)
        self.setPlayerInfoLabels(self._player._name)
        self.lineedit_newplayer.clear()

    def refreshReturningPlayerList(self):
        names = get_all_player_names(self._db)
        self.combo_returningplayer.clear()
        for name in names:
            self.combo_returningplayer.addItem(name)


    def refreshComPortList(self):
        self.list_comport.clear()
        ports = serial.tools.list_ports.comports()
        for port in ports:
            self.list_comport.addItem("{}    {}".format(port.device, port.description))

    def selectComPort(self):
        portobj = self.list_comport.selectedItems()
        if len(portobj) == 0:
            return # when nothing is selected

        for port in portobj:
            selectedport = str(port.text())
        selectedportparts = selectedport.split(" ")
        self._comport = selectedportparts[0]
        self.lbl_comport.setText("Port: {}".format(self._comport))

    def resetSerialOnThread(self):
        if (self._comport is None):
            self.lbl_comportstatus.setText("Status: Select COM Port")
        else:
            if (self._serialThread is None):
                self._serialThread = SerialThread()
                self._serialThread.supplyMessage.connect(self.printToComPortStatus)
            self._serialThread.resetSerial(self._comport, serialbaudrate, serialtimeout)

    def printToComPortStatus(self, inStr):
        self.lbl_comportstatus.setText(inStr)

    def analyzeMvc(self):
        if (not isinstance(self._player._mvcTrialData, np.ndarray)):
            self.lbl_livenotes("MVC Trial Data isn't Numpy Arr")
            return

        fig = plt.figure()
        ax = fig.add_subplot(111)
        Ts = 0.001 #sample time = 1 ms
        t = Ts*np.arange(0, len(self._player._mvcTrialData),1)
        data = self._player._mvcTrialData

        mvc = []
        ax.plot(t, data)
        for i in range(0, 2):
            ax.set_title("Pick the START of rest period {}".format(i))
            fig.canvas.draw()
            x = plt.ginput(1)
            indstart = np.where(t > x[0][0])[0][0]
            ax.set_title("Pick the END of rest period {}".format(i))
            fig.canvas.draw()
            x = plt.ginput(1)
            indstop = np.where(t < x[0][0])[0][-1]
            bottom = np.min(data)
            top = np.max(data)
            h = top - bottom
            l = t[indstart]
            r = t[indstop]
            w = r - l
            rect = Rectangle((l, bottom), w, h, facecolor='r', alpha=0.5)
            ax.add_patch(rect)
            zerolevel = np.mean(data[indstart:indstop])


            ax.set_title("Pick the START of flex period {}".format(i))
            fig.canvas.draw()
            x = plt.ginput(1)
            indstart = np.where(t > x[0][0])[0][0]
            ax.set_title("Pick the END of flex period {}".format(i))
            fig.canvas.draw()
            x = plt.ginput(1)
            indstop = np.where(t < x[0][0])[0][-1]
            bottom = np.min(data)
            top = np.max(data)
            h = top - bottom
            l = t[indstart]
            r = t[indstop]
            w = r - l
            rect = Rectangle((l, bottom), w, h, facecolor='g', alpha=0.5)
            ax.add_patch(rect)
            maxraw = np.max(data[indstart:indstop])
            mvc.append((maxraw-zerolevel)*serval2torqueNm)

            fig.canvas.draw()

        self._player._mvc = max(mvc)
        update_player_record(self._db,
                             self._player._name,
                             self._player._isAdult,
                             self._player._mvcTrialData,
                             self._player._mvc)
        self.setPlayerInfoLabels(self._player._name)
        plt.close()


    def addPlayer(self):
        newPlayerName = self.lineedit_newplayer.text()
        if len(newPlayerName) == 0:
            self.lbl_livenotes.setText("Enter Name")
            return

        self._player._name = newPlayerName
        if (self.checkbox_isadult.checkState() == 2):   # True
            self._player._isAdult = 1
        else:                                           # False
            self._player._isAdult = 0

        insert_success = insert_into_user_table(self._db, self._player._name, self._player._isAdult)
        if (insert_success == False):
            self.lbl_livenotes.setText("Duplicate Player Found")
            return

        self.setPlayerInfoLabels(self._player._name)
        self.refreshReturningPlayerList()

    def setPlayerInfoLabels(self, name):
        record = get_player_record(self._db, name)
        self._player._name = record[0][0]
        self._player._isAdult = record[0][1]
        self._player._mvcTrialData = np.frombuffer(record[0][2], np.float64).flatten() #convert from byte buffer to numpy array
        self._player._mvc = record[0][3]

        self.lbl_playername.setText("{}".format(self._player._name))
        if (self._player._mvc != 0):
            self.lbl_playermvc.setText("{:4.2f}".format(self._player._mvc))
        else:
            self.lbl_playermvc.setText("")


if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    sys.exit(app.exec_())
