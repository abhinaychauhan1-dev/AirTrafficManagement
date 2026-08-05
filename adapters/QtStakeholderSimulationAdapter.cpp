#include "QtStakeholderSimulationAdapter.h"

#include <QTime>
#include <QVariantMap>

namespace {

QString sourceName(atm::face::v1::Stakeholder source)
{
    using Stakeholder = atm::face::v1::Stakeholder;
    switch (source) {
    case Stakeholder::FleetOperator: return QStringLiteral("FLEET");
    case Stakeholder::VertiportOperator: return QStringLiteral("VERTIPORT");
    case Stakeholder::AnspPsu: return QStringLiteral("ANSP");
    case Stakeholder::UrbanAuthority: return QStringLiteral("CITY");
    case Stakeholder::System: return QStringLiteral("SYSTEM");
    }
    return QStringLiteral("UNKNOWN");
}

} // namespace

QtStakeholderSimulationAdapter::QtStakeholderSimulationAdapter(
    atm::face::interfaces::IStakeholderSimulation &simulation,
    atm::face::interfaces::IEventTransport &transport,
    QObject *parent)
    : QObject(parent)
    , m_simulation(simulation)
    , m_transport(transport)
{
    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, [this] {
        if (m_running && !m_mqttConnected)
            advanceSimulation();
    });
    m_timer.start();
}

QVariantList QtStakeholderSimulationAdapter::missions() const
{
    QVariantList result;
    for (const atm::face::v1::Mission &mission : m_simulation.missions()) {
        result.append(QVariantMap{
            {QStringLiteral("callSign"), QString::fromStdString(mission.callSign)},
            {QStringLiteral("route"), QString::fromStdString(mission.route)},
            {QStringLiteral("profile"), QString::fromStdString(mission.profile)},
            {QStringLiteral("departure"), QString::fromStdString(mission.departure)},
            {QStringLiteral("health"), mission.healthPercent},
            {QStringLiteral("status"), QString::fromStdString(mission.status)}
        });
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::vertiports() const
{
    QVariantList result;
    for (const atm::face::v1::Vertiport &vertiport : m_simulation.vertiports()) {
        result.append(QVariantMap{
            {QStringLiteral("name"), QString::fromStdString(vertiport.name)},
            {QStringLiteral("gates"), vertiport.gates},
            {QStringLiteral("freeGates"), vertiport.freeGates},
            {QStringLiteral("chargers"), vertiport.chargers},
            {QStringLiteral("freeChargers"), vertiport.freeChargers},
            {QStringLiteral("queue"), vertiport.passengerQueue},
            {QStringLiteral("turnaround"), vertiport.turnaroundMinutes},
            {QStringLiteral("status"), QString::fromStdString(vertiport.status)}
        });
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::slotRequests() const
{
    QVariantList result;
    for (const atm::face::v1::SlotRequest &slot : m_simulation.slotRequests()) {
        result.append(QVariantMap{
            {QStringLiteral("requestId"), QString::fromStdString(slot.requestId)},
            {QStringLiteral("callSign"), QString::fromStdString(slot.callSign)},
            {QStringLiteral("corridor"), QString::fromStdString(slot.corridor)},
            {QStringLiteral("desired"), QString::fromStdString(slot.desiredTime)},
            {QStringLiteral("status"), QString::fromStdString(slot.status)}
        });
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::complianceZones() const
{
    QVariantList result;
    for (const atm::face::v1::ComplianceZone &zone : m_simulation.complianceZones()) {
        result.append(QVariantMap{
            {QStringLiteral("name"), QString::fromStdString(zone.name)},
            {QStringLiteral("track"), QString::fromStdString(zone.track)},
            {QStringLiteral("cap"), zone.overflightCap},
            {QStringLiteral("current"), zone.currentOverflights},
            {QStringLiteral("noise"), zone.noiseDba},
            {QStringLiteral("enforced"), zone.enforced},
            {QStringLiteral("status"), QString::fromStdString(zone.status)}
        });
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::activityLog() const
{
    QVariantList result;
    for (const atm::face::v1::SimulationEvent &event : m_transport.events()) {
        const QTime time(event.simulationMinutes / 60, event.simulationMinutes % 60);
        result.append(QStringLiteral("%1  %2  %3").arg(
            time.toString(QStringLiteral("HH:mm")),
            sourceName(event.source).leftJustified(8),
            QString::fromStdString(event.message)));
    }
    return result;
}

QString QtStakeholderSimulationAdapter::simulationTime() const
{
    const int minutes = m_simulation.simulationMinutes();
    return QTime(minutes / 60, minutes % 60).toString(QStringLiteral("HH:mm"));
}

bool QtStakeholderSimulationAdapter::running() const { return m_running; }

bool QtStakeholderSimulationAdapter::mqttConnected() const { return m_mqttConnected; }

QString QtStakeholderSimulationAdapter::transportMode() const
{
    return m_mqttConnected ? QStringLiteral("MQTT LIVE") : QStringLiteral("BUILT-IN SIMULATION");
}

QString QtStakeholderSimulationAdapter::brokerDescription() const { return m_brokerDescription; }

void QtStakeholderSimulationAdapter::setBrokerDescription(const QString &description)
{
    if (m_brokerDescription == description)
        return;
    m_brokerDescription = description;
    emit transportChanged();
}

void QtStakeholderSimulationAdapter::setMqttConnected(bool connected)
{
    if (m_mqttConnected == connected)
        return;
    m_mqttConnected = connected;
    emit transportChanged();
}

void QtStakeholderSimulationAdapter::setRunning(bool running)
{
    if (m_running == running)
        return;
    m_running = running;
    emit runningChanged();
}

void QtStakeholderSimulationAdapter::planMission(int index, const QString &route, const QString &profile)
{
    if (index >= 0 && m_simulation.planMission(static_cast<std::size_t>(index),
            route.trimmed().toStdString(), profile.toStdString()))
        emitStateChanged();
}

void QtStakeholderSimulationAdapter::bookMission(int index)
{
    if (index >= 0 && m_simulation.bookMission(static_cast<std::size_t>(index)))
        emitStateChanged();
}

void QtStakeholderSimulationAdapter::delayMission(int index)
{
    if (index >= 0 && m_simulation.delayMission(static_cast<std::size_t>(index)))
        emitStateChanged();
}

void QtStakeholderSimulationAdapter::assignGate(int index)
{
    if (index >= 0 && m_simulation.assignGate(static_cast<std::size_t>(index)))
        emitStateChanged();
}

void QtStakeholderSimulationAdapter::startCharging(int index)
{
    if (index >= 0 && m_simulation.startCharging(static_cast<std::size_t>(index)))
        emitStateChanged();
}

void QtStakeholderSimulationAdapter::decideSlot(int index, bool granted)
{
    if (index >= 0 && m_simulation.decideSlot(static_cast<std::size_t>(index), granted))
        emitStateChanged();
}

void QtStakeholderSimulationAdapter::setBoundaryEnforcement(int index, bool enforced)
{
    if (index >= 0 && m_simulation.setBoundaryEnforcement(static_cast<std::size_t>(index), enforced))
        emitStateChanged();
}

void QtStakeholderSimulationAdapter::advanceSimulation()
{
    m_simulation.advance();
    emit simulationTimeChanged();
    emit vertiportsChanged();
}

void QtStakeholderSimulationAdapter::resetSimulation()
{
    m_simulation.reset();
    emitStateChanged();
    emit simulationTimeChanged();
}

void QtStakeholderSimulationAdapter::emitStateChanged()
{
    emit missionsChanged();
    emit vertiportsChanged();
    emit slotRequestsChanged();
    emit complianceZonesChanged();
    emit activityLogChanged();
}