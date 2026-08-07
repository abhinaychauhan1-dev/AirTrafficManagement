QT += quick quickcontrols2 network

CONFIG += c++17
CONFIG -= app_bundle

SOURCES += \
	main.cpp \
	adapters/MqttEventTransport.cpp \
	adapters/QtStakeholderSimulationAdapter.cpp \
	adapters/QtSurveillanceAdapter.cpp \
	face/components/StakeholderSimulationComponent.cpp \
	face/components/SurveillanceComponent.cpp \
	face/transport/InMemoryEventTransport.cpp \
	models/AirTaxiFilterProxyModel.cpp \
	models/AirTaxiListModel.cpp \
	viewmodels/AppShellViewModel.cpp \
	viewmodels/AirTrafficViewModel.cpp

HEADERS += \
	adapters/MqttEventTransport.h \
	adapters/QtStakeholderSimulationAdapter.h \
	adapters/QtSurveillanceAdapter.h \
	face/contracts/StakeholderData.h \
	face/contracts/v1/Surveillance.h \
	face/interfaces/IEventTransport.h \
	face/interfaces/IStakeholderSimulation.h \
	face/interfaces/ISurveillance.h \
	face/components/StakeholderSimulationComponent.h \
	face/components/SurveillanceComponent.h \
	face/transport/InMemoryEventTransport.h \
	models/AirTaxiFilterProxyModel.h \
	models/AirTaxiListModel.h \
	viewmodels/AppShellViewModel.h \
	viewmodels/AirTrafficViewModel.h

RESOURCES += qml.qrc

QML_SOURCES += \
	presentation/Main.qml \
	presentation/RadarScope.qml \
	presentation/AirspaceManager.qml \
	presentation/InteractiveComboBox.qml \
	presentation/MultiStakeholderView.qml \
	presentation/FeaturePlaceholder.qml

QML_FILES += $$QML_SOURCES
OTHER_FILES += $$QML_SOURCES

TARGET = AirTrafficManagement
