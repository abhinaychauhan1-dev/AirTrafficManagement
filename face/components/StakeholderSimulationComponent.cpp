#include "StakeholderSimulationComponent.h"

#include <algorithm>
#include <cctype>
#include <iomanip>
#include <sstream>

namespace atm::face::components {
namespace {

constexpr std::size_t kMaximumOperationalTextLength = 64;

bool isValidOperationalText(const std::string &value)
{
    return !value.empty() && value.size() <= kMaximumOperationalTextLength
        && std::all_of(value.cbegin(), value.cend(), [](unsigned char character) {
               return character >= 0x20 && character <= 0x7e;
           });
}

bool parseTime(const std::string &time, int &result)
{
    if (time.size() != 5 || time[2] != ':'
        || !std::isdigit(static_cast<unsigned char>(time[0]))
        || !std::isdigit(static_cast<unsigned char>(time[1]))
        || !std::isdigit(static_cast<unsigned char>(time[3]))
        || !std::isdigit(static_cast<unsigned char>(time[4])))
        return false;

    const int hours = (time[0] - '0') * 10 + (time[1] - '0');
    const int currentMinutes = (time[3] - '0') * 10 + (time[4] - '0');
    if (hours > 23 || currentMinutes > 59)
        return false;

    result = hours * 60 + currentMinutes;
    return true;
}

bool addMinutes(const std::string &time, int minutes, std::string &result)
{
    int parsedTime = 0;
    if (!parseTime(time, parsedTime))
        return false;

    const int total = (parsedTime + minutes) % (24 * 60);
    std::ostringstream stream;
    stream << std::setfill('0') << std::setw(2) << total / 60 << ':' << std::setw(2) << total % 60;
    result = stream.str();
    return true;
}

bool participatesInCoordination(atm::face::v1::OperationalIntentState state)
{
    using State = atm::face::v1::OperationalIntentState;
    return state == State::Accepted || state == State::Activated
        || state == State::Nonconforming || state == State::Contingent;
}

bool timeWindowsOverlap(const atm::face::v1::SlotRequest &left,
                        const atm::face::v1::SlotRequest &right)
{
    return left.startMinute < right.endMinute && right.startMinute < left.endMinute;
}

bool altitudeBandsOverlap(const atm::face::v1::SlotRequest &left,
                          const atm::face::v1::SlotRequest &right)
{
    return left.minimumAltitudeFt < right.maximumAltitudeFt
        && right.minimumAltitudeFt < left.maximumAltitudeFt;
}

bool isValidOperationalVolume(const atm::face::v1::SlotRequest &slot)
{
    return !slot.operationalIntentId.empty() && slot.operationalIntentId.size() <= 64
        && !slot.corridor.empty() && slot.corridor.size() <= 64
        && slot.startMinute >= 0 && slot.startMinute < 24 * 60
        && slot.endMinute > slot.startMinute && slot.endMinute <= 24 * 60
        && slot.minimumAltitudeFt >= 0
        && slot.maximumAltitudeFt > slot.minimumAltitudeFt
        && slot.maximumAltitudeFt <= 10000;
}

} // namespace

StakeholderSimulationComponent::StakeholderSimulationComponent(interfaces::IEventTransport &transport)
    : m_transport(transport)
{
    reset();
}

const std::vector<v1::Mission> &StakeholderSimulationComponent::missions() const { return m_missions; }
const std::vector<v1::Vertiport> &StakeholderSimulationComponent::vertiports() const { return m_vertiports; }
const std::vector<v1::SlotRequest> &StakeholderSimulationComponent::slotRequests() const { return m_slotRequests; }
const std::vector<v1::ComplianceZone> &StakeholderSimulationComponent::complianceZones() const { return m_complianceZones; }
const std::vector<v1::SafetyRisk> &StakeholderSimulationComponent::safetyRisks() const { return m_safetyRisks; }
int StakeholderSimulationComponent::simulationMinutes() const { return m_minutes; }

bool StakeholderSimulationComponent::planMission(std::size_t index, const std::string &route, const std::string &profile)
{
    if (index >= m_missions.size() || !isValidOperationalText(route)
        || !isValidOperationalText(profile) || route.find(" - ") == std::string::npos)
        return false;
    v1::Mission &mission = m_missions[index];
    mission.route = route;
    mission.profile = profile;
    mission.status = mission.healthPercent < 60 ? "HEALTH REVIEW" : "PLANNED";
    const auto slot = std::find_if(m_slotRequests.begin(), m_slotRequests.end(), [&](const v1::SlotRequest &request) {
        return request.callSign == mission.callSign;
    });
    if (slot != m_slotRequests.end()) {
        ++slot->revision;
        slot->state = v1::OperationalIntentState::Draft;
        slot->status = "REVIEW";
        slot->conflictReason.clear();
        publish(v1::Stakeholder::FleetOperator, mission.callSign + " route planned via " + route,
                slot->operationalIntentId, slot->revision);
    } else {
        publish(v1::Stakeholder::FleetOperator, mission.callSign + " route planned via " + route);
    }
    return true;
}

bool StakeholderSimulationComponent::bookMission(std::size_t index)
{
    if (index >= m_missions.size())
        return false;
    v1::Mission &mission = m_missions[index];
    if (mission.healthPercent < 60) {
        mission.status = "BLOCKED - HEALTH";
        publish(v1::Stakeholder::FleetOperator, mission.callSign + " booking blocked by fleet health");
        return true;
    }
    mission.status = "BOOKED";
    const auto slot = std::find_if(m_slotRequests.begin(), m_slotRequests.end(), [&](const v1::SlotRequest &request) {
        return request.callSign == mission.callSign;
    });
    if (slot != m_slotRequests.end()) {
        ++slot->revision;
        slot->state = v1::OperationalIntentState::Submitted;
        slot->status = "PENDING";
        slot->conflictReason.clear();
        publish(v1::Stakeholder::FleetOperator, mission.callSign + " operational intent submitted",
                slot->operationalIntentId, slot->revision);
    }
    publish(v1::Stakeholder::FleetOperator, mission.callSign + " mission booked; slot requested");
    return true;
}

bool StakeholderSimulationComponent::delayMission(std::size_t index)
{
    if (index >= m_missions.size())
        return false;
    v1::Mission &mission = m_missions[index];
    std::string delayedDeparture;
    if (!addMinutes(mission.departure, 5, delayedDeparture))
        return false;
    mission.departure = delayedDeparture;
    mission.status = "RESCHEDULED";
    const auto slot = std::find_if(m_slotRequests.begin(), m_slotRequests.end(), [&](const v1::SlotRequest &request) {
        return request.callSign == mission.callSign;
    });
    if (slot != m_slotRequests.end()) {
        const int duration = std::max(1, slot->endMinute - slot->startMinute);
        int delayedStart = 0;
        if (!parseTime(delayedDeparture, delayedStart))
            return false;
        ++slot->revision;
        slot->desiredTime = mission.departure;
        slot->startMinute = delayedStart;
        slot->endMinute = delayedStart + duration;
        slot->state = v1::OperationalIntentState::Draft;
        slot->status = "REVIEW";
        slot->conflictReason.clear();
        publish(v1::Stakeholder::FleetOperator, mission.callSign + " operational intent revised",
                slot->operationalIntentId, slot->revision);
    }
    publish(v1::Stakeholder::FleetOperator, mission.callSign + " delayed 5 min; slot returned for review");
    return true;
}

bool StakeholderSimulationComponent::assignGate(std::size_t index, const std::string &callSign)
{
    if (index >= m_vertiports.size() || callSign.empty())
        return false;
    v1::Vertiport &vertiport = m_vertiports[index];
    const auto mission = std::find_if(m_missions.begin(), m_missions.end(), [&](const v1::Mission &candidate) {
        return candidate.callSign == callSign;
    });
    if (mission == m_missions.end() || mission->route.find(vertiport.name) == std::string::npos
        || mission->status == "GATE ASSIGNED" || mission->status == "CHARGING"
        || !vertiport.turnaroundCallSign.empty())
        return false;
    if (vertiport.freeGates == 0) {
        vertiport.status = "GATE WAITLIST";
        updateMissionStatus(callSign, "GATE WAITLIST");
        publish(v1::Stakeholder::VertiportOperator, callSign + " gate request waitlisted at " + vertiport.name);
    } else {
        --vertiport.freeGates;
        vertiport.passengerQueue = std::max(0, vertiport.passengerQueue - 8);
        vertiport.turnaroundMinutes = 18;
        vertiport.status = "TURNAROUND";
        vertiport.turnaroundCallSign = callSign;
        updateMissionStatus(callSign, "GATE ASSIGNED");
        publish(v1::Stakeholder::VertiportOperator, callSign + " assigned gate at " + vertiport.name + "; loading started");
    }
    return true;
}

bool StakeholderSimulationComponent::startCharging(std::size_t index, const std::string &callSign)
{
    if (index >= m_vertiports.size() || callSign.empty())
        return false;
    v1::Vertiport &vertiport = m_vertiports[index];
    const auto mission = std::find_if(m_missions.begin(), m_missions.end(), [&](const v1::Mission &candidate) {
        return candidate.callSign == callSign;
    });
    if (mission == m_missions.end() || vertiport.turnaroundCallSign != callSign
        || !vertiport.chargingCallSign.empty()
        || (mission->status != "GATE ASSIGNED" && mission->status != "CHARGER QUEUE"))
        return false;
    if (vertiport.freeChargers == 0) {
        vertiport.status = "TURNAROUND / CHARGER QUEUE";
        updateMissionStatus(callSign, "CHARGER QUEUE");
        publish(v1::Stakeholder::VertiportOperator, callSign + " charger request queued at " + vertiport.name);
    } else {
        --vertiport.freeChargers;
        vertiport.chargingMinutes = 10;
        vertiport.status = "CHARGING";
        vertiport.chargingCallSign = callSign;
        updateMissionStatus(callSign, "CHARGING");
        publish(v1::Stakeholder::VertiportOperator, vertiport.name + " charging "
            + vertiport.chargingCallSign + "; 10 min remaining");
    }
    return true;
}

bool StakeholderSimulationComponent::decideSlot(std::size_t index, bool granted)
{
    if (index >= m_slotRequests.size())
        return false;
    v1::SlotRequest &slot = m_slotRequests[index];
    if (slot.state != v1::OperationalIntentState::Submitted)
        return false;
    ++slot.revision;
    slot.conflictReason.clear();
    if (m_minutes >= slot.endMinute) {
        slot.state = v1::OperationalIntentState::Rejected;
        slot.status = "EXPIRED";
        slot.conflictReason = "DECISION WINDOW ELAPSED";
        updateMissionStatus(slot.callSign, "INTENT EXPIRED");
        publish(v1::Stakeholder::AnspPsu, slot.callSign + " intent rejected: decision window elapsed",
                slot.operationalIntentId, slot.revision);
        return true;
    }
    if (granted && !isValidOperationalVolume(slot)) {
        slot.state = v1::OperationalIntentState::Rejected;
        slot.status = "INVALID VOLUME";
        slot.conflictReason = "4D VOLUME FAILED VALIDATION";
        updateMissionStatus(slot.callSign, "INTENT INVALID");
        publish(v1::Stakeholder::AnspPsu, slot.callSign + " intent rejected: invalid 4D volume",
                slot.operationalIntentId, slot.revision);
        return true;
    }
    const auto restrictedZone = std::find_if(m_complianceZones.begin(), m_complianceZones.end(), [&](const v1::ComplianceZone &zone) {
        return zone.track == slot.corridor && zone.enforced
            && zone.currentOverflights >= zone.overflightCap;
    });
    if (granted && restrictedZone != m_complianceZones.end()) {
        slot.state = v1::OperationalIntentState::Conflict;
        slot.status = "HELD - NOISE";
        slot.conflictReason = "ACTIVE CONSTRAINT: " + restrictedZone->name;
        updateMissionStatus(slot.callSign, "COMPLIANCE HOLD");
        publish(v1::Stakeholder::AnspPsu, slot.callSign + " intent held by " + restrictedZone->name,
                slot.operationalIntentId, slot.revision);
        return true;
    }

    if (granted) {
        const auto conflictingSlot = std::find_if(m_slotRequests.cbegin(), m_slotRequests.cend(), [&](const v1::SlotRequest &candidate) {
            return &candidate != &slot && candidate.corridor == slot.corridor
                && participatesInCoordination(candidate.state)
                && timeWindowsOverlap(candidate, slot) && altitudeBandsOverlap(candidate, slot);
        });
        if (conflictingSlot != m_slotRequests.cend()) {
            slot.state = v1::OperationalIntentState::Conflict;
            slot.status = "STRATEGIC CONFLICT";
            slot.conflictReason = "OVERLAP WITH " + conflictingSlot->operationalIntentId;
            updateMissionStatus(slot.callSign, "STRATEGIC CONFLICT");
            publish(v1::Stakeholder::AnspPsu, slot.callSign + " intent requires coordination with "
                    + conflictingSlot->operationalIntentId, slot.operationalIntentId, slot.revision);
            return true;
        }
    }
    slot.state = granted ? v1::OperationalIntentState::Accepted
                         : v1::OperationalIntentState::Rejected;
    slot.status = granted ? "GRANTED" : "DENIED";
    updateMissionStatus(slot.callSign, granted ? "SLOT GRANTED" : "SLOT DENIED");
        publish(v1::Stakeholder::AnspPsu, slot.callSign + " intent " + (granted ? "accepted" : "rejected") + " on " + slot.corridor,
            slot.operationalIntentId, slot.revision);
    return true;
}

bool StakeholderSimulationComponent::setBoundaryEnforcement(std::size_t index, bool enforced)
{
    if (index >= m_complianceZones.size())
        return false;
    v1::ComplianceZone &zone = m_complianceZones[index];
    if (zone.enforced == enforced)
        return false;
    zone.enforced = enforced;
    const bool capReached = zone.currentOverflights >= zone.overflightCap;
    zone.status = enforced ? (capReached ? "CAP ENFORCED" : "BOUNDARY ACTIVE") : "MONITOR ONLY";
    if (enforced && capReached) {
        for (v1::SlotRequest &slot : m_slotRequests) {
            if (slot.corridor != zone.track)
                continue;
            if (slot.state == v1::OperationalIntentState::Activated
                || slot.state == v1::OperationalIntentState::Nonconforming) {
                ++slot.revision;
                slot.state = v1::OperationalIntentState::Contingent;
                slot.status = "CONTINGENT";
                slot.conflictReason = "ACTIVE CONSTRAINT: " + zone.name;
                updateMissionStatus(slot.callSign, "CONTINGENCY ACTIVE");
                publish(v1::Stakeholder::UrbanAuthority, slot.callSign + " entered contingency due to " + zone.name,
                    slot.operationalIntentId, slot.revision);
            } else if (slot.state == v1::OperationalIntentState::Accepted
                       || slot.state == v1::OperationalIntentState::Submitted) {
                ++slot.revision;
                slot.state = v1::OperationalIntentState::Conflict;
                slot.status = "HELD - NOISE";
                slot.conflictReason = "ACTIVE CONSTRAINT: " + zone.name;
                updateMissionStatus(slot.callSign, "COMPLIANCE HOLD");
                publish(v1::Stakeholder::UrbanAuthority, slot.callSign + " intent held by " + zone.name,
                    slot.operationalIntentId, slot.revision);
            }
        }
    } else if (!enforced) {
        for (v1::SlotRequest &slot : m_slotRequests) {
            if (slot.corridor != zone.track)
                continue;
            if (slot.state == v1::OperationalIntentState::Contingent
                && slot.conflictReason == "ACTIVE CONSTRAINT: " + zone.name) {
                ++slot.revision;
                slot.state = m_minutes >= slot.startMinute && m_minutes < slot.endMinute
                    ? v1::OperationalIntentState::Activated
                    : v1::OperationalIntentState::Closed;
                slot.status = slot.state == v1::OperationalIntentState::Activated ? "ACTIVE" : "CLOSED";
                slot.conflictReason.clear();
                updateMissionStatus(slot.callSign, slot.state == v1::OperationalIntentState::Activated
                    ? "OPERATION ACTIVE" : "COMPLETED");
                publish(v1::Stakeholder::UrbanAuthority, slot.callSign + " contingency cleared after constraint release",
                    slot.operationalIntentId, slot.revision);
            } else if (slot.status == "HELD - NOISE") {
                ++slot.revision;
                slot.state = v1::OperationalIntentState::Draft;
                slot.status = "REVIEW";
                slot.conflictReason.clear();
                updateMissionStatus(slot.callSign, "SLOT REVIEW");
                publish(v1::Stakeholder::UrbanAuthority, slot.callSign + " intent returned for coordination review",
                    slot.operationalIntentId, slot.revision);
            }
        }
    }
    publish(v1::Stakeholder::UrbanAuthority, zone.name + (enforced
        ? " compliance boundary enforced" : " switched to monitor only"));
    for (v1::SafetyRisk &risk : m_safetyRisks) {
        if (risk.action != v1::SafetyMitigationAction::EnforceBoundary
            || risk.linkedEntity != zone.track || risk.status == v1::SafetyRiskStatus::Closed)
            continue;
        const v1::SafetyRiskStatus nextStatus = enforced ? v1::SafetyRiskStatus::Monitoring
                                                         : v1::SafetyRiskStatus::MitigationRequired;
        if (risk.status == nextStatus)
            continue;
        ++risk.revision;
        risk.status = nextStatus;
        publish(v1::Stakeholder::UrbanAuthority,
                risk.riskId + (enforced ? " mitigation under assurance monitoring"
                                        : " mitigation withdrawn; reassessment required"),
                risk.riskId, risk.revision);
    }
    return true;
}

bool StakeholderSimulationComponent::applySafetyMitigation(std::size_t index)
{
    if (index >= m_safetyRisks.size())
        return false;
    v1::SafetyRisk &risk = m_safetyRisks[index];
    if (risk.status != v1::SafetyRiskStatus::MitigationRequired)
        return false;

    if (risk.action == v1::SafetyMitigationAction::BlockDispatch) {
        const auto mission = std::find_if(m_missions.begin(), m_missions.end(), [&](const v1::Mission &candidate) {
            return candidate.callSign == risk.linkedCallSign;
        });
        if (mission == m_missions.end())
            return false;
        if (mission->healthPercent >= 60) {
            mission->status = "READY";
            risk.status = v1::SafetyRiskStatus::Closed;
        } else {
            mission->status = "BLOCKED - SAFETY RISK";
            risk.status = v1::SafetyRiskStatus::Monitoring;
        }
    } else if (risk.action == v1::SafetyMitigationAction::EnforceBoundary) {
        const auto zone = std::find_if(m_complianceZones.begin(), m_complianceZones.end(), [&](const v1::ComplianceZone &candidate) {
            return candidate.track == risk.linkedEntity;
        });
        if (zone == m_complianceZones.end())
            return false;
        const std::size_t zoneIndex = static_cast<std::size_t>(std::distance(m_complianceZones.begin(), zone));
        if (!zone->enforced)
            return setBoundaryEnforcement(zoneIndex, true);
        risk.status = v1::SafetyRiskStatus::Monitoring;
    }

    ++risk.revision;
    publish(v1::Stakeholder::System, risk.riskId + " mitigation applied by " + risk.owner,
            risk.riskId, risk.revision);
    return true;
}

void StakeholderSimulationComponent::advance()
{
    m_minutes = (m_minutes + 1) % (24 * 60);
    for (v1::SlotRequest &slot : m_slotRequests) {
        if (slot.state == v1::OperationalIntentState::Accepted
            && m_minutes >= slot.startMinute && m_minutes < slot.endMinute) {
            ++slot.revision;
            slot.state = v1::OperationalIntentState::Activated;
            slot.status = "ACTIVE";
            updateZoneOccupancy(slot.corridor, 1);
            updateMissionStatus(slot.callSign, "OPERATION ACTIVE");
            publish(v1::Stakeholder::System, slot.callSign + " operational intent activated",
                    slot.operationalIntentId, slot.revision);
        } else if (slot.state == v1::OperationalIntentState::Activated
                   && m_minutes >= slot.endMinute) {
            ++slot.revision;
            slot.state = v1::OperationalIntentState::Closed;
            slot.status = "CLOSED";
            updateZoneOccupancy(slot.corridor, -1);
            updateMissionStatus(slot.callSign, "COMPLETED");
            publish(v1::Stakeholder::System, slot.callSign + " operational intent closed",
                    slot.operationalIntentId, slot.revision);
        } else if ((slot.state == v1::OperationalIntentState::Draft
                    || slot.state == v1::OperationalIntentState::Submitted)
                   && m_minutes >= slot.endMinute) {
            ++slot.revision;
            slot.state = v1::OperationalIntentState::Rejected;
            slot.status = "EXPIRED";
            slot.conflictReason = "OPERATIONAL WINDOW ELAPSED";
            updateMissionStatus(slot.callSign, "INTENT EXPIRED");
            publish(v1::Stakeholder::System, slot.callSign + " operational intent expired without activation",
                    slot.operationalIntentId, slot.revision);
        } else if (slot.state == v1::OperationalIntentState::Contingent
                   && m_minutes >= slot.endMinute) {
            ++slot.revision;
            slot.state = v1::OperationalIntentState::Closed;
            slot.status = "CLOSED - CONTINGENCY";
            updateZoneOccupancy(slot.corridor, -1);
            updateMissionStatus(slot.callSign, "COMPLETED - REVIEW");
            publish(v1::Stakeholder::System, slot.callSign + " contingent operation closed; review required",
                    slot.operationalIntentId, slot.revision);
        }
    }
    for (std::size_t index = 0; index < m_vertiports.size(); ++index) {
        v1::Vertiport &vertiport = m_vertiports[index];
        if (!vertiport.turnaroundCallSign.empty() && vertiport.turnaroundMinutes > 0)
            --vertiport.turnaroundMinutes;

        if (!vertiport.chargingCallSign.empty() && vertiport.chargingMinutes > 0)
            --vertiport.chargingMinutes;
        if (vertiport.chargingMinutes == 0 && !vertiport.chargingCallSign.empty()) {
            const auto mission = std::find_if(m_missions.begin(), m_missions.end(), [&](const v1::Mission &candidate) {
                return candidate.callSign == vertiport.chargingCallSign;
            });
            if (mission != m_missions.end()) {
                mission->healthPercent = std::min(100, mission->healthPercent + 20);
                mission->status = mission->healthPercent < 60 ? "HEALTH REVIEW" : "READY";
                if (mission->healthPercent >= 60) {
                    for (v1::SafetyRisk &risk : m_safetyRisks) {
                        if (risk.action == v1::SafetyMitigationAction::BlockDispatch
                            && risk.linkedCallSign == mission->callSign
                            && risk.status != v1::SafetyRiskStatus::Closed) {
                            ++risk.revision;
                            risk.status = v1::SafetyRiskStatus::Closed;
                            publish(v1::Stakeholder::System, risk.riskId + " closed after vehicle health recovery",
                                    risk.riskId, risk.revision);
                        }
                    }
                }
            }
            vertiport.freeChargers = std::min(vertiport.chargers, vertiport.freeChargers + 1);
            publish(v1::Stakeholder::VertiportOperator, vertiport.name + " charging complete for " + vertiport.chargingCallSign);
            vertiport.chargingCallSign.clear();
            vertiport.status = "TURNAROUND";
        }

        if (!vertiport.turnaroundCallSign.empty() && vertiport.turnaroundMinutes == 0
            && vertiport.chargingCallSign.empty()) {
            const std::string completedCallSign = vertiport.turnaroundCallSign;
            vertiport.turnaroundCallSign.clear();
            vertiport.freeGates = std::min(vertiport.gates, vertiport.freeGates + 1);
            vertiport.status = "AVAILABLE";
            const auto mission = std::find_if(m_missions.begin(), m_missions.end(), [&](const v1::Mission &candidate) {
                return candidate.callSign == completedCallSign;
            });
            if (mission != m_missions.end() && (mission->status == "GATE ASSIGNED"
                || mission->status == "CHARGER QUEUE"))
                mission->status = "TURNAROUND COMPLETE";
            publish(v1::Stakeholder::VertiportOperator,
                    vertiport.name + " turnaround complete for " + completedCallSign);
        }
    }
}

void StakeholderSimulationComponent::reset()
{
    m_minutes = 8 * 60 + 15;
    m_missions = {
        {"ATX201", "VPT-GGM - VPT-IGI", "COMMUTER", "08:20", 86, "READY"},
        {"SKY114", "VPT-NOIDA - VPT-CP", "CARGO", "08:25", 54, "HEALTH REVIEW"},
        {"URB308", "VPT-DILLI - VPT-IGI", "AIRPORT", "08:32", 73, "PLANNED"}
    };
    m_vertiports = {
        {"VPT-IGI", 6, 2, 4, 1, 34, 12, "BUSY", 0, "", "BASELINE-IGI"},
        {"VPT-NOIDA", 4, 1, 3, 2, 18, 7, "BUSY", 0, "", "BASELINE-NOIDA"},
        {"VPT-GGM", 5, 0, 3, 1, 27, 16, "SATURATED", 0, "", "BASELINE-GGM"},
        {"VPT-CP", 3, 2, 2, 1, 12, 8, "BUSY", 0, "", "BASELINE-CP"},
        {"VPT-DILLI", 4, 3, 2, 2, 16, 6, "BUSY", 0, "", "BASELINE-DILLI"}
    };
    m_slotRequests = {
        {"SL-1042", "OI-DEL-0001042", 1, "ATX201", "C-DELTA", "08:20", 500, 510, 800, 1400, v1::OperationalIntentState::Submitted, "PENDING", ""},
        {"SL-1043", "OI-DEL-0001043", 1, "SKY114", "C-ECHO", "08:25", 505, 515, 1200, 2000, v1::OperationalIntentState::Draft, "REVIEW", ""},
        {"SL-1044", "OI-DEL-0001044", 1, "URB308", "C-BRAVO", "08:32", 512, 522, 1800, 2400, v1::OperationalIntentState::Submitted, "PENDING", ""}
    };
    m_complianceZones = {
        {"SOUTH DELHI QUIET ZONE", "C-DELTA", 18, 16, 61, true, "BOUNDARY ACTIVE"},
        {"YAMUNA ECO BOUNDARY", "C-ECHO", 12, 12, 57, false, "CAP REACHED"},
        {"CENTRAL NIGHT BUFFER", "C-BRAVO", 8, 5, 54, true, "COMPLIANT"}
    };
    m_safetyRisks = {
        {"SR-003", 1, "CORRIDOR OPERATING NEAR CAPACITY",
         "REDUCED CAPACITY MARGIN MAY REQUIRE FLOW RESTRICTION", "ATX201", "C-DELTA",
         "UTM DUTY MANAGER", "MAINTAIN BOUNDARY ENFORCEMENT AND MONITOR OVERFLIGHT TREND",
         3, 3, 1, 3, v1::SafetyRiskStatus::Monitoring,
         v1::SafetyMitigationAction::EnforceBoundary},
        {"SR-001", 1, "VEHICLE HEALTH BELOW DISPATCH THRESHOLD",
         "REDUCED PROPULSION OR ENERGY MARGIN", "SKY114", "SKY114",
         "FLEET SAFETY MANAGER", "BLOCK DISPATCH UNTIL HEALTH IS AT LEAST 60 PERCENT",
         3, 4, 1, 4, v1::SafetyRiskStatus::MitigationRequired,
         v1::SafetyMitigationAction::BlockDispatch},
        {"SR-002", 1, "CORRIDOR CAPACITY LIMIT REACHED",
         "EXCESS COMMUNITY EXPOSURE OR LOSS OF AIRSPACE CAPACITY", "SKY114", "C-ECHO",
         "UTM DUTY MANAGER", "ENFORCE THE CORRIDOR BOUNDARY AND HOLD NEW INTENTS",
         3, 3, 1, 3, v1::SafetyRiskStatus::MitigationRequired,
         v1::SafetyMitigationAction::EnforceBoundary}
    };
    m_transport.clear();
    publish(v1::Stakeholder::FleetOperator, "ATX201 ready for VPT-GGM departure");
    publish(v1::Stakeholder::FleetOperator, "SKY114 held for vehicle health review");
    publish(v1::Stakeholder::FleetOperator, "URB308 mission plan awaiting slot");
    publish(v1::Stakeholder::AnspPsu, "SL-1043 queued for flow review");
    publish(v1::Stakeholder::UrbanAuthority, "ECO-7 overflight cap reached");
    publish(v1::Stakeholder::System, "Shared stakeholder simulation initialized");
}

void StakeholderSimulationComponent::publish(v1::Stakeholder source, const std::string &message,
                                             const std::string &correlationId, std::uint32_t entityVersion)
{
    m_transport.publish({v1::kSchemaVersion, 0, m_minutes, source, message,
                         correlationId, entityVersion});
}

void StakeholderSimulationComponent::updateZoneOccupancy(const std::string &corridor, int delta)
{
    const auto zone = std::find_if(m_complianceZones.begin(), m_complianceZones.end(), [&](const v1::ComplianceZone &candidate) {
        return candidate.track == corridor;
    });
    if (zone == m_complianceZones.end())
        return;
    zone->currentOverflights = std::max(0, zone->currentOverflights + delta);
    if (zone->currentOverflights >= zone->overflightCap)
        zone->status = zone->enforced ? "CAP ENFORCED" : "CAP REACHED";
    else
        zone->status = zone->enforced ? "BOUNDARY ACTIVE" : "MONITOR ONLY";
}

void StakeholderSimulationComponent::updateMissionStatus(const std::string &callSign, const std::string &status)
{
    const auto mission = std::find_if(m_missions.begin(), m_missions.end(), [&](const v1::Mission &candidate) {
        return candidate.callSign == callSign;
    });
    if (mission != m_missions.end())
        mission->status = status;
}

} // namespace atm::face::components