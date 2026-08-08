#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "adapters/MqttEventTransport.h"
#include "adapters/QtStakeholderSimulationAdapter.h"
#include "adapters/QtSurveillanceAdapter.h"
#include "face/components/StakeholderSimulationComponent.h"
#include "face/components/SurveillanceComponent.h"
#include "viewmodels/AppShellViewModel.h"
#include "viewmodels/AirTrafficViewModel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Air Taxi Traffic Management"));
    QGuiApplication::setOrganizationName(QStringLiteral("Air Taxi Systems"));

    AirTrafficViewModel viewModel;
    atm::face::components::SurveillanceComponent surveillance;
    QtSurveillanceAdapter surveillanceAdapter(surveillance, viewModel.airTaxiListModel(), viewModel);
    AppShellViewModel shellViewModel;
    MqttEventTransport eventTransport;
    atm::face::components::StakeholderSimulationComponent stakeholderSimulation(eventTransport);
    QtStakeholderSimulationAdapter stakeholderViewModel(stakeholderSimulation, eventTransport);
    QObject::connect(&eventTransport, &MqttEventTransport::connectedChanged,
                     &stakeholderViewModel, &QtStakeholderSimulationAdapter::setMqttConnected);
    QObject::connect(&eventTransport, &MqttEventTransport::eventsChanged,
                     &stakeholderViewModel, &QtStakeholderSimulationAdapter::activeMissionChanged);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("airTrafficViewModel"), &viewModel);
    engine.rootContext()->setContextProperty(QStringLiteral("appShellViewModel"), &shellViewModel);
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
