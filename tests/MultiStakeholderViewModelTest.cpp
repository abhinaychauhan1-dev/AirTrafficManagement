#include "adapters/QtStakeholderSimulationAdapter.h"
#include "face/components/StakeholderSimulationComponent.h"
#include "face/transport/InMemoryEventTransport.h"

#include <QtTest>

class MultiStakeholderViewModelTest final : public QObject
{
    Q_OBJECT

private slots:
    void bookingRespectsFleetHealth();
    void slotDecisionPropagatesToMission();
    void vertiportResourcesCompleteTheirLifecycle();
    void complianceCapHoldsPendingOperations();
    void manualStepWorksWhilePaused();
    void mqttConnectionControlsSimulationFallback();
    void mqttEventFeedRejectsLocalMutations();
    void invalidActionsProvideFeedback();
    void eventsUseVersionedMonotonicContract();
};

struct SimulationFixture {
    atm::face::transport::InMemoryEventTransport transport;
    atm::face::components::StakeholderSimulationComponent simulation{transport};
    QtStakeholderSimulationAdapter viewModel{simulation, transport};

    SimulationFixture() { viewModel.setRunning(false); }
};

void MultiStakeholderViewModelTest::bookingRespectsFleetHealth()
{
    SimulationFixture fixture;
    QtStakeholderSimulationAdapter &viewModel = fixture.viewModel;

    viewModel.bookMission(1);
    QCOMPARE(viewModel.missions().at(1).toMap().value("status").toString(), QString("BLOCKED - HEALTH"));

    viewModel.bookMission(0);
    QCOMPARE(viewModel.missions().at(0).toMap().value("status").toString(), QString("BOOKED"));
    QCOMPARE(viewModel.slotRequests().at(0).toMap().value("status").toString(), QString("PENDING"));
}

void MultiStakeholderViewModelTest::slotDecisionPropagatesToMission()
{
    SimulationFixture fixture;
    QtStakeholderSimulationAdapter &viewModel = fixture.viewModel;

    viewModel.decideSlot(0, true);
    QCOMPARE(viewModel.slotRequests().at(0).toMap().value("status").toString(), QString("GRANTED"));
    QCOMPARE(viewModel.missions().at(0).toMap().value("status").toString(), QString("SLOT GRANTED"));

    viewModel.decideSlot(2, false);
    QCOMPARE(viewModel.missions().at(2).toMap().value("status").toString(), QString("SLOT DENIED"));
}

void MultiStakeholderViewModelTest::vertiportResourcesCompleteTheirLifecycle()
{
    SimulationFixture fixture;
    QtStakeholderSimulationAdapter &viewModel = fixture.viewModel;

    viewModel.assignGate(0);
    const QVariantMap gatedVertiport = viewModel.vertiports().at(0).toMap();
    QCOMPARE(gatedVertiport.value("freeGates").toInt(), 1);
    QCOMPARE(gatedVertiport.value("queue").toInt(), 26);
    QCOMPARE(gatedVertiport.value("status").toString(), QString("TURNAROUND"));

    viewModel.startCharging(1);
    QCOMPARE(viewModel.vertiports().at(1).toMap().value("freeChargers").toInt(), 1);
    QCOMPARE(viewModel.vertiports().at(1).toMap().value("chargingMinutes").toInt(), 10);
    QCOMPARE(viewModel.missions().at(1).toMap().value("health").toInt(), 54);

    for (int minute = 0; minute < 10; ++minute)
        viewModel.advanceSimulation();

    QCOMPARE(viewModel.vertiports().at(1).toMap().value("freeChargers").toInt(), 2);
    QCOMPARE(viewModel.vertiports().at(1).toMap().value("chargingMinutes").toInt(), 0);
    QCOMPARE(viewModel.missions().at(1).toMap().value("health").toInt(), 74);
    QCOMPARE(viewModel.missions().at(1).toMap().value("status").toString(), QString("READY"));
}

void MultiStakeholderViewModelTest::complianceCapHoldsPendingOperations()
{
    SimulationFixture fixture;
    QtStakeholderSimulationAdapter &viewModel = fixture.viewModel;

    viewModel.setBoundaryEnforcement(1, true);
    QCOMPARE(viewModel.complianceZones().at(1).toMap().value("status").toString(), QString("CAP ENFORCED"));
    QCOMPARE(viewModel.slotRequests().at(0).toMap().value("status").toString(), QString("HELD - NOISE"));
    QCOMPARE(viewModel.slotRequests().at(1).toMap().value("status").toString(), QString("HELD - NOISE"));
    QCOMPARE(viewModel.missions().at(0).toMap().value("status").toString(), QString("COMPLIANCE HOLD"));

    viewModel.setBoundaryEnforcement(1, false);
    QCOMPARE(viewModel.slotRequests().at(0).toMap().value("status").toString(), QString("REVIEW"));
    QCOMPARE(viewModel.missions().at(0).toMap().value("status").toString(), QString("SLOT REVIEW"));
}

void MultiStakeholderViewModelTest::manualStepWorksWhilePaused()
{
    SimulationFixture fixture;
    QtStakeholderSimulationAdapter &viewModel = fixture.viewModel;

    QCOMPARE(viewModel.simulationTime(), QString("08:15"));
    viewModel.advanceSimulation();
    QCOMPARE(viewModel.simulationTime(), QString("08:16"));
}

void MultiStakeholderViewModelTest::mqttConnectionControlsSimulationFallback()
{
    SimulationFixture fixture;
    QtStakeholderSimulationAdapter &viewModel = fixture.viewModel;
    viewModel.setRunning(true);

    QTRY_COMPARE_WITH_TIMEOUT(viewModel.simulationTime(), QString("08:16"), 1500);
    viewModel.setMqttConnected(true);
    const QString liveTime = viewModel.simulationTime();
    QTest::qWait(1200);
    QCOMPARE(viewModel.simulationTime(), liveTime);
    QCOMPARE(viewModel.transportMode(), QString("MQTT EVENT FEED"));
    QVERIFY(!viewModel.localControlsEnabled());
    QVERIFY(!viewModel.manualStepEnabled());

    viewModel.setMqttConnected(false);
    QTRY_VERIFY_WITH_TIMEOUT(viewModel.simulationTime() != liveTime, 1500);
    QCOMPARE(viewModel.transportMode(), QString("LOCAL SIMULATION"));
    QVERIFY(viewModel.localControlsEnabled());
}

void MultiStakeholderViewModelTest::mqttEventFeedRejectsLocalMutations()
{
    SimulationFixture fixture;
    QtStakeholderSimulationAdapter &viewModel = fixture.viewModel;
    viewModel.setMqttConnected(true);

    const QString initialTime = viewModel.simulationTime();
    viewModel.advanceSimulation();
    QCOMPARE(viewModel.simulationTime(), initialTime);
    QCOMPARE(viewModel.actionSeverity(), QString("warning"));
    QVERIFY(viewModel.actionMessage().contains(QString("unavailable")));

    viewModel.resetSimulation();
    QCOMPARE(viewModel.simulationTime(), initialTime);
}

void MultiStakeholderViewModelTest::invalidActionsProvideFeedback()
{
    SimulationFixture fixture;
    fixture.viewModel.bookMission(-1);

    QCOMPARE(fixture.viewModel.actionSeverity(), QString("warning"));
    QCOMPARE(fixture.viewModel.actionMessage(), QString("Select a mission to book."));
}

void MultiStakeholderViewModelTest::eventsUseVersionedMonotonicContract()
{
    SimulationFixture fixture;
    const std::uint64_t previousSequence = fixture.transport.events().front().sequence;

    fixture.viewModel.bookMission(0);
    const atm::face::v1::SimulationEvent &event = fixture.transport.events().front();
    QCOMPARE(event.schemaVersion, atm::face::v1::kSchemaVersion);
    QVERIFY(event.sequence > previousSequence);
    QCOMPARE(event.source, atm::face::v1::Stakeholder::FleetOperator);
}

QTEST_GUILESS_MAIN(MultiStakeholderViewModelTest)

#include "MultiStakeholderViewModelTest.moc"