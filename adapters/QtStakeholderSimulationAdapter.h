#pragma once

#include "face/interfaces/IEventTransport.h"
#include "face/interfaces/IStakeholderSimulation.h"

#include <QObject>
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
    Q_PROPERTY(QString simulationTime READ simulationTime NOTIFY simulationTimeChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(bool mqttConnected READ mqttConnected NOTIFY transportChanged)
    Q_PROPERTY(QString transportMode READ transportMode NOTIFY transportChanged)
    Q_PROPERTY(QString brokerDescription READ brokerDescription NOTIFY transportChanged)

public:
    QtStakeholderSimulationAdapter(atm::face::interfaces::IStakeholderSimulation &simulation,
                                   atm::face::interfaces::IEventTransport &transport,
                                   QObject *parent = nullptr);

    QVariantList missions() const;
    QVariantList vertiports() const;
    QVariantList slotRequests() const;
    QVariantList complianceZones() const;
    QVariantList activityLog() const;
    QString simulationTime() const;
    bool running() const;
    void setRunning(bool running);
    bool mqttConnected() const;
    QString transportMode() const;
    QString brokerDescription() const;
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

signals:
    void missionsChanged();
    void vertiportsChanged();
    void slotRequestsChanged();
    void complianceZonesChanged();
    void activityLogChanged();
    void simulationTimeChanged();
    void runningChanged();
    void transportChanged();

private:
    void emitStateChanged();

    atm::face::interfaces::IStakeholderSimulation &m_simulation;
    atm::face::interfaces::IEventTransport &m_transport;
    QTimer m_timer;
    QString m_brokerDescription;
    bool m_running = true;
    bool m_mqttConnected = false;
};