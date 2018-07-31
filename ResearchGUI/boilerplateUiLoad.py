#!/usr/bin/python3

import sys
from PyQt5.QtWidgets import *
from PyQt5 import QtCore, QtGui, QtWidgets, uic


class MainWindow(QtWidgets.QMainWindow):
    def __init__(self):
        super(MainWindow, self).__init__()
        uic.loadUi('ResearchGui.ui', self)
        self.show()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    sys.exit(app.exec_())
