#include "StakeholderSimulationComponent.h"

#include <algorithm>
#include <iomanip>
#include <sstream>

namespace atm::face::components {
namespace {

std::string addMinutes(const std::string &time, int minutes)
{
    const int hours = std::stoi(time.substr(0, 2));
    const int currentMinutes = std::stoi(time.substr(3, 2));
    const int total = (hours * 60 + currentMinutes + minutes) % (24 * 60);
    std::ostringstream stream;
    stream << std::setfill('0') << std::setw(2) << total / 60 << ':' << std::setw(2) << total % 60;
    return stream.str();
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
int StakeholderSimulationComponent::simulationMinutes() const { return m_minutes; }

bool StakeholderSimulationComponent::planMission(std::size_t index, const std::string &route, const std::string &profile)
{
    if (index >= m_missions.size() || route.empty())
        return false;
    v1::Mission &mission = m_missions[index];
    mission.route = route;
    mission.profile = profile;
    mission.status = mission.healthPercent < 60 ? "HEALTH REVIEW" : "PLANNED";
    publish(v1::Stakeholder::FleetOperator, mission.callSign + " route planned via " + route);
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
    if (slot != m_slotRequests.end())
        slot->status = "PENDING";
    publish(v1::Stakeholder::FleetOperator, mission.callSign + " mission booked; slot requested");
    return true;
}

bool StakeholderSimulationComponent::delayMission(std::size_t index)
{
    if (index >= m_missions.size())
        return false;
    v1::Mission &mission = m_missions[index];
    mission.departure = addMinutes(mission.departure, 5);
    mission.status = "RESCHEDULED";
    const auto slot = std::find_if(m_slotRequests.begin(), m_slotRequests.end(), [&](const v1::SlotRequest &request) {
        return request.callSign == mission.callSign;
    });
    if (slot != m_slotRequests.end()) {
        slot->desiredTime = mission.departure;
        slot->status = "REVIEW";
    }
    publish(v1::Stakeholder::FleetOperator, mission.callSign + " delayed 5 min; slot returned for review");
    return true;
}

bool StakeholderSimulationComponent::assignGate(std::size_t index)
{
    if (index >= m_vertiports.size())
        return false;
    v1::Vertiport &vertiport = m_vertiports[index];
    if (vertiport.freeGates == 0) {
        vertiport.status = "GATE WAITLIST";
        publish(v1::Stakeholder::VertiportOperator, vertiport.name + " gate request waitlisted");
    } else {
        --vertiport.freeGates;
        vertiport.passengerQueue = std::max(0, vertiport.passengerQueue - 8);
        vertiport.turnaroundMinutes = 18;
        vertiport.status = "TURNAROUND";
        publish(v1::Stakeholder::VertiportOperator, vertiport.name + " assigned gate; loading started");
    }
    return true;
}

bool StakeholderSimulationComponent::startCharging(std::size_t index)
{
    if (index >= m_vertiports.size())
        return false;
    v1::Vertiport &vertiport = m_vertiports[index];
    if (vertiport.freeChargers == 0) {
        vertiport.status = "CHARGER QUEUE";
        publish(v1::Stakeholder::VertiportOperator, vertiport.name + " charger request queued");
    } else {
        --vertiport.freeChargers;
        vertiport.chargingMinutes = 10;
        vertiport.status = "CHARGING";
        if (!m_missions.empty()) {
            const auto mission = std::min_element(m_missions.begin(), m_missions.end(), [](const v1::Mission &left, const v1::Mission &right) {
                return left.healthPercent < right.healthPercent;
            });
            vertiport.chargingCallSign = mission->callSign;
        }
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
    slot.status = granted ? "GRANTED" : "DENIED";
    updateMissionStatus(slot.callSign, granted ? "SLOT GRANTED" : "SLOT DENIED");
    publish(v1::Stakeholder::AnspPsu, slot.callSign + " slot " + (granted ? "granted" : "denied") + " on " + slot.corridor);
    return true;
}

bool StakeholderSimulationComponent::setBoundaryEnforcement(std::size_t index, bool enforced)
{
    if (index >= m_complianceZones.size())
        return false;
    v1::ComplianceZone &zone = m_complianceZones[index];
    zone.enforced = enforced;
    const bool capReached = zone.currentOverflights >= zone.overflightCap;
    zone.status = enforced ? (capReached ? "CAP ENFORCED" : "BOUNDARY ACTIVE") : "MONITOR ONLY";
    if (enforced && capReached) {
        for (v1::SlotRequest &slot : m_slotRequests) {
            if (slot.status == "PENDING" || slot.status == "REVIEW") {
                slot.status = "HELD - NOISE";
                updateMissionStatus(slot.callSign, "COMPLIANCE HOLD");
            }
        }
    } else if (!enforced) {
        for (v1::SlotRequest &slot : m_slotRequests) {
            if (slot.status == "HELD - NOISE") {
                slot.status = "REVIEW";
                updateMissionStatus(slot.callSign, "SLOT REVIEW");
            }
        }
    }
    publish(v1::Stakeholder::UrbanAuthority, zone.name + (enforced
        ? " compliance boundary enforced" : " switched to monitor only"));
    return true;
}

void StakeholderSimulationComponent::advance()
{
    m_minutes = (m_minutes + 1) % (24 * 60);
    for (v1::Vertiport &vertiport : m_vertiports) {
        if (vertiport.turnaroundMinutes > 0)
            --vertiport.turnaroundMinutes;
        if (vertiport.turnaroundMinutes == 0 && vertiport.freeGates < vertiport.gates) {
            vertiport.freeGates = std::min(vertiport.gates, vertiport.freeGates + 1);
            if (vertiport.chargingMinutes == 0)
                vertiport.status = "AVAILABLE";
        }

        if (vertiport.chargingMinutes > 0)
            --vertiport.chargingMinutes;
        if (vertiport.chargingMinutes == 0 && !vertiport.chargingCallSign.empty()) {
            const auto mission = std::find_if(m_missions.begin(), m_missions.end(), [&](const v1::Mission &candidate) {
                return candidate.callSign == vertiport.chargingCallSign;
            });
            if (mission != m_missions.end()) {
                mission->healthPercent = std::min(100, mission->healthPercent + 20);
                mission->status = mission->healthPercent < 60 ? "HEALTH REVIEW" : "READY";
            }
            vertiport.freeChargers = std::min(vertiport.chargers, vertiport.freeChargers + 1);
            publish(v1::Stakeholder::VertiportOperator, vertiport.name + " charging complete for " + vertiport.chargingCallSign);
            vertiport.chargingCallSign.clear();
            vertiport.status = vertiport.turnaroundMinutes > 0 ? "TURNAROUND" : "AVAILABLE";
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
        {"VPT-IGI", 6, 2, 4, 1, 34, 12, "BUSY", 0, ""},
        {"VPT-NOIDA", 4, 1, 3, 2, 18, 7, "AVAILABLE", 0, ""},
        {"VPT-GGM", 5, 0, 3, 1, 27, 16, "SATURATED", 0, ""},
        {"VPT-CP", 3, 2, 2, 1, 12, 8, "AVAILABLE", 0, ""},
        {"VPT-DILLI", 4, 3, 2, 2, 16, 6, "AVAILABLE", 0, ""}
    };
    m_slotRequests = {
        {"SL-1042", "ATX201", "C-DELTA", "08:20", "PENDING"},
        {"SL-1043", "SKY114", "C-ECHO", "08:25", "REVIEW"},
        {"SL-1044", "URB308", "C-BRAVO", "08:32", "PENDING"}
    };
    m_complianceZones = {
        {"SOUTH DELHI QUIET ZONE", "C-DELTA", 18, 16, 61, true, "BOUNDARY ACTIVE"},
        {"YAMUNA ECO BOUNDARY", "C-ECHO", 12, 12, 57, false, "CAP REACHED"},
        {"CENTRAL NIGHT BUFFER", "C-BRAVO", 8, 5, 54, true, "COMPLIANT"}
    };
    m_transport.clear();
    publish(v1::Stakeholder::FleetOperator, "ATX201 ready for VPT-GGM departure");
    publish(v1::Stakeholder::FleetOperator, "SKY114 held for vehicle health review");
    publish(v1::Stakeholder::FleetOperator, "URB308 mission plan awaiting slot");
    publish(v1::Stakeholder::AnspPsu, "SL-1043 queued for flow review");
    publish(v1::Stakeholder::UrbanAuthority, "ECO-7 overflight cap reached");
    publish(v1::Stakeholder::System, "Shared stakeholder simulation initialized");
}

void StakeholderSimulationComponent::publish(v1::Stakeholder source, const std::string &message)
{
    m_transport.publish({v1::kSchemaVersion, 0, m_minutes, source, message});
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