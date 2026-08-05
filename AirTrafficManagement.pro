QT += quick quickcontrols2 network

CONFIG += c++17
CONFIG -= app_bundle

SOURCES += \
	main.cpp \
	adapters/MqttEventTransport.cpp \
	adapters/QtStakeholderSimulationAdapter.cpp \
	face/components/StakeholderSimulationComponent.cpp \
	face/transport/InMemoryEventTransport.cpp \
	models/FlightListModel.cpp \
	viewmodels/AirTrafficViewModel.cpp

HEADERS += \
	adapters/MqttEventTransport.h \
	adapters/QtStakeholderSimulationAdapter.h \
	face/contracts/StakeholderData.h \
	face/interfaces/IEventTransport.h \
	face/interfaces/IStakeholderSimulation.h \
	face/components/StakeholderSimulationComponent.h \
	face/transport/InMemoryEventTransport.h \
	models/FlightListModel.h \
	viewmodels/AirTrafficViewModel.h

RESOURCES += qml.qrc

QML_SOURCES += \
	presentation/Main.qml \
	presentation/RadarScope.qml \
	presentation/MultiStakeholderView.qml \
	presentation/FeaturePlaceholder.qml

QML_FILES += $$QML_SOURCES
OTHER_FILES += $$QML_SOURCES

TARGET = AirTrafficManagement
