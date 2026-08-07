QT += core testlib

CONFIG += console c++17 testcase
CONFIG -= app_bundle

TEMPLATE = app
TARGET = SurveillanceViewModelTest

INCLUDEPATH += ..

SOURCES += \
    SurveillanceViewModelTest.cpp \
    ../models/FlightFilterProxyModel.cpp \
    ../models/FlightListModel.cpp \
    ../viewmodels/AirTrafficViewModel.cpp

HEADERS += \
    ../models/FlightFilterProxyModel.h \
    ../models/FlightListModel.h \
    ../viewmodels/AirTrafficViewModel.h