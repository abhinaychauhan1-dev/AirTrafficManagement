#include "QtStakeholderSimulationAdapter.h"

#include <QTime>
#include <QVariantMap>
#include <cstddef> // For std::size_t
#include <string> // For std::string

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
    int sourceIndex = 0;
    for (const atm::face::v1::Mission &mission : m_simulation.missions()) {
        const bool canBook = mission.healthPercent >= 60;
        result.append(QVariantMap{
            {QStringLiteral("callSign"), QString::fromStdString(mission.callSign)},
            {QStringLiteral("route"), QString::fromStdString(mission.route)},
            {QStringLiteral("profile"), QString::fromStdString(mission.profile)},
            {QStringLiteral("departure"), QString::fromStdString(mission.departure)},
            {QStringLiteral("health"), mission.healthPercent},
            {QStringLiteral("status"), QString::fromStdString(mission.status)},
            {QStringLiteral("canBook"), canBook},
            {QStringLiteral("severity"), canBook ? QStringLiteral("normal") : QStringLiteral("warning")}
            , {QStringLiteral("sourceIndex"), sourceIndex++}
        });
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::vertiports() const
{
    QVariantList result;
    int sourceIndex = 0;
    for (const atm::face::v1::Vertiport &vertiport : m_simulation.vertiports()) {
        const bool saturated = vertiport.freeGates == 0;
        result.append(QVariantMap{
            {QStringLiteral("name"), QString::fromStdString(vertiport.name)},
            {QStringLiteral("gates"), vertiport.gates},
            {QStringLiteral("freeGates"), vertiport.freeGates},
            {QStringLiteral("chargers"), vertiport.chargers},
            {QStringLiteral("freeChargers"), vertiport.freeChargers},
            {QStringLiteral("queue"), vertiport.passengerQueue},
            {QStringLiteral("turnaround"), vertiport.turnaroundMinutes},
            {QStringLiteral("chargingMinutes"), vertiport.chargingMinutes},
            {QStringLiteral("chargingCallSign"), QString::fromStdString(vertiport.chargingCallSign)},
            {QStringLiteral("status"), QString::fromStdString(vertiport.status)},
            {QStringLiteral("saturated"), saturated},
            {QStringLiteral("severity"), saturated ? QStringLiteral("warning") : QStringLiteral("normal")}
            , {QStringLiteral("sourceIndex"), sourceIndex++}
        });
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::slotRequests() const
{
    QVariantList result;
    int sourceIndex = 0;
    for (const atm::face::v1::SlotRequest &slot : m_simulation.slotRequests()) {
        const QString status = QString::fromStdString(slot.status);
        const bool adverse = status == QStringLiteral("DENIED") || status == QStringLiteral("HELD - NOISE");
        result.append(QVariantMap{
            {QStringLiteral("requestId"), QString::fromStdString(slot.requestId)},
            {QStringLiteral("callSign"), QString::fromStdString(slot.callSign)},
            {QStringLiteral("corridor"), QString::fromStdString(slot.corridor)},
            {QStringLiteral("desired"), QString::fromStdString(slot.desiredTime)},
            {QStringLiteral("status"), status},
            {QStringLiteral("severity"), adverse ? QStringLiteral("warning") : QStringLiteral("normal")}
            , {QStringLiteral("sourceIndex"), sourceIndex++}
        });
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::complianceZones() const
{
    QVariantList result;
    int sourceIndex = 0;
    for (const atm::face::v1::ComplianceZone &zone : m_simulation.complianceZones()) {
        const bool capExceeded = zone.currentOverflights >= zone.overflightCap;
        result.append(QVariantMap{
            {QStringLiteral("name"), QString::fromStdString(zone.name)},
            {QStringLiteral("track"), QString::fromStdString(zone.track)},
            {QStringLiteral("cap"), zone.overflightCap},
            {QStringLiteral("current"), zone.currentOverflights},
            {QStringLiteral("noise"), zone.noiseDba},
            {QStringLiteral("enforced"), zone.enforced},
            {QStringLiteral("status"), QString::fromStdString(zone.status)},
            {QStringLiteral("capExceeded"), capExceeded},
            {QStringLiteral("severity"), capExceeded ? QStringLiteral("warning") : QStringLiteral("normal")}
            , {QStringLiteral("sourceIndex"), sourceIndex++}
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

int QtStakeholderSimulationAdapter::activeMissionIndex() const
{
    return m_activeMissionIndex;
}

void QtStakeholderSimulationAdapter::setActiveMissionIndex(int index)
{
    const int missionCount = static_cast<int>(m_simulation.missions().size());
    const int boundedIndex = missionCount > 0 ? qBound(0, index, missionCount - 1) : -1;
    if (m_activeMissionIndex == boundedIndex)
        return;
    m_activeMissionIndex = boundedIndex;
    emit activeMissionChanged();
}

QVariantMap QtStakeholderSimulationAdapter::activeMission() const
{
    const QVariantList allMissions = missions();
    return m_activeMissionIndex >= 0 && m_activeMissionIndex < allMissions.size()
        ? allMissions.at(m_activeMissionIndex).toMap() : QVariantMap{};
}

QVariantList QtStakeholderSimulationAdapter::activeMissionSlots() const
{
    QVariantList result;
    const QString callSign = activeMission().value(QStringLiteral("callSign")).toString();
    for (const QVariant &entry : slotRequests()) {
        if (entry.toMap().value(QStringLiteral("callSign")).toString() == callSign)
            result.append(entry);
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::activeMissionVertiports() const
{
    QVariantList result;
    const QString route = activeMission().value(QStringLiteral("route")).toString();
    const QStringList endpoints = route.split(QStringLiteral(" - "));
    for (const QVariant &entry : vertiports()) {
        const QVariantMap vertiport = entry.toMap();
        if (endpoints.contains(vertiport.value(QStringLiteral("name")).toString()))
            result.append(entry);
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::activeMissionComplianceZones() const
{
    QVariantList result;
    const QVariantList missionSlots = activeMissionSlots();
    const QString corridor = missionSlots.isEmpty() ? QString() : missionSlots.first().toMap().value(QStringLiteral("corridor")).toString();
    for (const QVariant &entry : complianceZones()) {
        if (entry.toMap().value(QStringLiteral("track")).toString() == corridor)
            result.append(entry);
    }
    return result;
}

QVariantList QtStakeholderSimulationAdapter::activeMissionActivity() const
{
    QVariantList result;
    const QString callSign = activeMission().value(QStringLiteral("callSign")).toString();
    for (const QVariant &entry : activityLog()) {
        if (entry.toString().contains(callSign, Qt::CaseInsensitive))
            result.append(entry);
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
    return m_mqttConnected ? QStringLiteral("MQTT EVENT FEED") : QStringLiteral("LOCAL SIMULATION");
}

QString QtStakeholderSimulationAdapter::brokerDescription() const { return m_brokerDescription; }

QString QtStakeholderSimulationAdapter::transportStatusText() const
{
    return m_mqttConnected ? m_brokerDescription : QStringLiteral("MQTT OFFLINE");
}

QStringList QtStakeholderSimulationAdapter::stakeholderTabs() const
{
    return {QStringLiteral("MISSION"), QStringLiteral("VERTIPORTS"),
        QStringLiteral("UTM SLOT"), QStringLiteral("COMPLIANCE")};
}

QStringList QtStakeholderSimulationAdapter::routeOptions() const
{
    return {QStringLiteral("VPT-GGM - VPT-IGI"), QStringLiteral("VPT-NOIDA - VPT-CP"),
        QStringLiteral("VPT-DILLI - VPT-IGI"), QStringLiteral("VPT-NOIDA - VPT-GGM")};
}

QStringList QtStakeholderSimulationAdapter::missionProfiles() const
{
    return {QStringLiteral("COMMUTER"), QStringLiteral("AIRPORT"),
            QStringLiteral("CARGO"), QStringLiteral("MEDEVAC")};
}

QVariantMap QtStakeholderSimulationAdapter::workflowNotes() const
{
    return {
        {"booking", "Health below 60% blocks booking"},
        {"vertiport", "Resources update in shared time"},
        {"slot", "Decisions propagate to fleet status"},
        {"compliance", "Cap enforcement holds pending slots"}
    };
}

bool QtStakeholderSimulationAdapter::localControlsEnabled() const { return !m_mqttConnected; }

bool QtStakeholderSimulationAdapter::manualStepEnabled() const { return !m_running && localControlsEnabled(); }

QString QtStakeholderSimulationAdapter::actionMessage() const { return m_actionMessage; }

QString QtStakeholderSimulationAdapter::actionSeverity() const { return m_actionSeverity; }

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
    emit controlStateChanged();
    reportAction(connected
        ? QStringLiteral("MQTT event feed connected. Local simulation controls are read-only.")
        : QStringLiteral("MQTT unavailable. Local simulation controls restored."), true);
}

void QtStakeholderSimulationAdapter::setRunning(bool running)
{
    if (m_running == running)
        return;
    m_running = running;
    emit runningChanged();
    emit controlStateChanged();
}

void QtStakeholderSimulationAdapter::planMission(int index, const QString &route, const QString &profile)
{
    if (!actionAllowed(QStringLiteral("Plan route")))
        return;
    const bool success = index >= 0 && m_simulation.planMission(static_cast<std::size_t>(index),
        route.trimmed().toStdString(), profile.toStdString());
    if (success)
        emitStateChanged();
    reportAction(success ? QStringLiteral("Route plan updated.") : QStringLiteral("Select a mission and a valid route."), success);
}

void QtStakeholderSimulationAdapter::bookMission(int index)
{
    if (!actionAllowed(QStringLiteral("Book mission")))
        return;
    const bool success = index >= 0 && m_simulation.bookMission(static_cast<std::size_t>(index));
    if (success)
        emitStateChanged();
    reportAction(success ? QStringLiteral("Mission booking evaluated.") : QStringLiteral("Select a mission to book."), success);
}

void QtStakeholderSimulationAdapter::delayMission(int index)
{
    if (!actionAllowed(QStringLiteral("Delay mission")))
        return;
    const bool success = index >= 0 && m_simulation.delayMission(static_cast<std::size_t>(index));
    if (success)
        emitStateChanged();
    reportAction(success ? QStringLiteral("Mission delayed by five minutes; slot returned for review.") : QStringLiteral("Select a mission to delay."), success);
}

void QtStakeholderSimulationAdapter::assignGate(int index)
{
    if (!actionAllowed(QStringLiteral("Assign gate")))
        return;
    const bool success = index >= 0 && m_simulation.assignGate(static_cast<std::size_t>(index));
    if (success)
        emitStateChanged();
    reportAction(success ? QStringLiteral("Gate request processed.") : QStringLiteral("Select a vertiport."), success);
}

void QtStakeholderSimulationAdapter::startCharging(int index)
{
    if (!actionAllowed(QStringLiteral("Start charging")))
        return;
    const bool success = index >= 0 && m_simulation.startCharging(static_cast<std::size_t>(index));
    if (success)
        emitStateChanged();
    reportAction(success ? QStringLiteral("Charging request processed.") : QStringLiteral("Select a vertiport."), success);
}

void QtStakeholderSimulationAdapter::decideSlot(int index, bool granted)
{
    if (!actionAllowed(granted ? QStringLiteral("Grant slot") : QStringLiteral("Deny slot")))
        return;
    const bool success = index >= 0 && m_simulation.decideSlot(static_cast<std::size_t>(index), granted);
    if (success)
        emitStateChanged();
    reportAction(success ? (granted ? QStringLiteral("Slot granted.") : QStringLiteral("Slot denied."))
                         : QStringLiteral("Select a slot request."), success);
}

void QtStakeholderSimulationAdapter::setBoundaryEnforcement(int index, bool enforced)
{
    if (!actionAllowed(enforced ? QStringLiteral("Enforce boundary") : QStringLiteral("Set monitor only")))
        return;
    const bool success = index >= 0 && m_simulation.setBoundaryEnforcement(static_cast<std::size_t>(index), enforced);
    if (success)
        emitStateChanged();
    reportAction(success ? (enforced ? QStringLiteral("Boundary enforcement applied.") : QStringLiteral("Boundary set to monitor only; held slots returned for review."))
                         : QStringLiteral("Select a compliance zone."), success);
}

void QtStakeholderSimulationAdapter::advanceSimulation()
{
    if (!actionAllowed(QStringLiteral("Step simulation")))
        return;
    m_simulation.advance();
    emitStateChanged();
    emit simulationTimeChanged();
}

void QtStakeholderSimulationAdapter::resetSimulation()
{
    if (!actionAllowed(QStringLiteral("Reset simulation")))
        return;
    m_simulation.reset();
    emitStateChanged();
    emit simulationTimeChanged();
    reportAction(QStringLiteral("Local simulation reset to 08:15."), true);
}

bool QtStakeholderSimulationAdapter::actionAllowed(const QString &action)
{
    if (localControlsEnabled())
        return true;
    reportAction(action + QStringLiteral(" is unavailable while the MQTT event feed is connected."), false);
    return false;
}

void QtStakeholderSimulationAdapter::reportAction(const QString &message, bool success)
{
    m_actionMessage = message;
    m_actionSeverity = success ? QStringLiteral("success") : QStringLiteral("warning");
    emit actionFeedbackChanged();
}

void QtStakeholderSimulationAdapter::emitStateChanged()
{
    emit missionsChanged();
    emit vertiportsChanged();
    emit slotRequestsChanged();
    emit complianceZonesChanged();
    emit activityLogChanged();
    emit activeMissionChanged();
}

void QtStakeholderSimulationAdapter::toggleRunning()
{
    if (!actionAllowed(QStringLiteral("Run or pause simulation")))
        return;
    setRunning(!m_running);
    reportAction(m_running ? QStringLiteral("Local simulation running.") : QStringLiteral("Local simulation paused."), true);
}