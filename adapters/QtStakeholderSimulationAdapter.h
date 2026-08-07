#pragma once

#include "face/interfaces/IEventTransport.h"
#include "face/interfaces/IStakeholderSimulation.h"

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>

class QtStakeholderSimulationAdapter final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList missions READ missions NOTIFY missionsChanged)
    Q_PROPERTY(QVariantList vertiports READ vertiports NOTIFY vertiportsChanged)
    Q_PROPERTY(QVariantList slotRequests READ slotRequests NOTIFY slotRequestsChanged)
    Q_PROPERTY(QVariantList complianceZones READ complianceZones NOTIFY complianceZonesChanged)
    Q_PROPERTY(QVariantList activityLog READ activityLog NOTIFY activityLogChanged)
    Q_PROPERTY(int activeMissionIndex READ activeMissionIndex WRITE setActiveMissionIndex NOTIFY activeMissionChanged)
    Q_PROPERTY(QVariantMap activeMission READ activeMission NOTIFY activeMissionChanged)
    Q_PROPERTY(QVariantList activeMissionVertiports READ activeMissionVertiports NOTIFY activeMissionChanged)
    Q_PROPERTY(QVariantList activeMissionSlots READ activeMissionSlots NOTIFY activeMissionChanged)
    Q_PROPERTY(QVariantList activeMissionComplianceZones READ activeMissionComplianceZones NOTIFY activeMissionChanged)
    Q_PROPERTY(QVariantList activeMissionActivity READ activeMissionActivity NOTIFY activeMissionChanged)
    Q_PROPERTY(QString simulationTime READ simulationTime NOTIFY simulationTimeChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(bool mqttConnected READ mqttConnected NOTIFY transportChanged)
    Q_PROPERTY(QString transportMode READ transportMode NOTIFY transportChanged)
    Q_PROPERTY(QString brokerDescription READ brokerDescription NOTIFY transportChanged)
    Q_PROPERTY(QString transportStatusText READ transportStatusText NOTIFY transportChanged)
    Q_PROPERTY(QStringList stakeholderTabs READ stakeholderTabs CONSTANT)
    Q_PROPERTY(QStringList routeOptions READ routeOptions CONSTANT)
    Q_PROPERTY(QStringList missionProfiles READ missionProfiles CONSTANT)
    Q_PROPERTY(QVariantMap workflowNotes READ workflowNotes CONSTANT)
    Q_PROPERTY(bool localControlsEnabled READ localControlsEnabled NOTIFY transportChanged)
    Q_PROPERTY(bool manualStepEnabled READ manualStepEnabled NOTIFY controlStateChanged)
    Q_PROPERTY(QString actionMessage READ actionMessage NOTIFY actionFeedbackChanged)
    Q_PROPERTY(QString actionSeverity READ actionSeverity NOTIFY actionFeedbackChanged)

public:
    QtStakeholderSimulationAdapter(atm::face::interfaces::IStakeholderSimulation &simulation,
                                   atm::face::interfaces::IEventTransport &transport,
                                   QObject *parent = nullptr);

    QVariantList missions() const;
    QVariantList vertiports() const;
    QVariantList slotRequests() const;
    QVariantList complianceZones() const;
    QVariantList activityLog() const;
    int activeMissionIndex() const;
    void setActiveMissionIndex(int index);
    QVariantMap activeMission() const;
    QVariantList activeMissionVertiports() const;
    QVariantList activeMissionSlots() const;
    QVariantList activeMissionComplianceZones() const;
    QVariantList activeMissionActivity() const;
    QString simulationTime() const;
    bool running() const;
    void setRunning(bool running);
    bool mqttConnected() const;
    QString transportMode() const;
    QString brokerDescription() const;
    QString transportStatusText() const;
    QStringList stakeholderTabs() const;
    QStringList routeOptions() const;
    QStringList missionProfiles() const;
    QVariantMap workflowNotes() const;
    bool localControlsEnabled() const;
    bool manualStepEnabled() const;
    QString actionMessage() const;
    QString actionSeverity() const;
    void setBrokerDescription(const QString &description);

public slots:
    void setMqttConnected(bool connected);

    Q_INVOKABLE void planMission(int index, const QString &route, const QString &profile);
    Q_INVOKABLE void bookMission(int index);
    Q_INVOKABLE void delayMission(int index);
    Q_INVOKABLE void assignGate(int index);
    Q_INVOKABLE void startCharging(int index);
    Q_INVOKABLE void decideSlot(int index, bool granted);
    Q_INVOKABLE void setBoundaryEnforcement(int index, bool enforced);
    Q_INVOKABLE void advanceSimulation();
    Q_INVOKABLE void resetSimulation();
    Q_INVOKABLE void toggleRunning();

signals:
    void missionsChanged();
    void vertiportsChanged();
    void slotRequestsChanged();
    void complianceZonesChanged();
    void activityLogChanged();
    void activeMissionChanged();
    void simulationTimeChanged();
    void runningChanged();
    void transportChanged();
    void controlStateChanged();
    void actionFeedbackChanged();

private:
    bool actionAllowed(const QString &action);
    void reportAction(const QString &message, bool success);
    void emitStateChanged();

    atm::face::interfaces::IStakeholderSimulation &m_simulation;
    atm::face::interfaces::IEventTransport &m_transport;
    QTimer m_timer;
    QString m_brokerDescription;
    QString m_actionMessage;
    QString m_actionSeverity = QStringLiteral("info");
    int m_activeMissionIndex = 0;
    bool m_running = true;
    bool m_mqttConnected = false;
};