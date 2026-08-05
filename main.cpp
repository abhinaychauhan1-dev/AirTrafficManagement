#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "adapters/MqttEventTransport.h"
#include "adapters/QtStakeholderSimulationAdapter.h"
#include "face/components/StakeholderSimulationComponent.h"
#include "viewmodels/AirTrafficViewModel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Air Traffic Management"));
    QGuiApplication::setOrganizationName(QStringLiteral("ATM Systems"));

    AirTrafficViewModel viewModel;
    MqttEventTransport eventTransport;
    atm::face::components::StakeholderSimulationComponent stakeholderSimulation(eventTransport);
    QtStakeholderSimulationAdapter stakeholderViewModel(stakeholderSimulation, eventTransport);
    stakeholderViewModel.setBrokerDescription(eventTransport.brokerDescription());
    QObject::connect(&eventTransport, &MqttEventTransport::connectedChanged,
                     &stakeholderViewModel, &QtStakeholderSimulationAdapter::setMqttConnected);
    QObject::connect(&eventTransport, &MqttEventTransport::eventsChanged,
                     &stakeholderViewModel, &QtStakeholderSimulationAdapter::activityLogChanged);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("airTrafficViewModel"), &viewModel);
    engine.rootContext()->setContextProperty(QStringLiteral("stakeholderSimulationViewModel"), &stakeholderViewModel);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [] { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/AirTrafficManagement/presentation/Main.qml")));

    return app.exec();
}
