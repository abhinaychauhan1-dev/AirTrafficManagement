QT += core testlib

CONFIG += console c++17 testcase
CONFIG -= app_bundle

TEMPLATE = app
TARGET = MultiStakeholderViewModelTest

INCLUDEPATH += ..

SOURCES += \
    MultiStakeholderViewModelTest.cpp \
    ../adapters/QtStakeholderSimulationAdapter.cpp \
    ../face/components/StakeholderSimulationComponent.cpp \
    ../face/transport/InMemoryEventTransport.cpp

HEADERS += \
    ../adapters/QtStakeholderSimulationAdapter.h \
    ../face/contracts/StakeholderData.h \
    ../face/interfaces/IEventTransport.h \
    ../face/interfaces/IStakeholderSimulation.h \
    ../face/components/StakeholderSimulationComponent.h \
    ../face/transport/InMemoryEventTransport.h