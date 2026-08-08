#pragma once

#include "face/contracts/StakeholderData.h"

#include <cstddef>
#include <string>
#include <vector>

namespace atm::face::interfaces {

class IStakeholderSimulation
{
public:
    virtual ~IStakeholderSimulation() = default;

    virtual const std::vector<v1::Mission> &missions() const = 0;
    virtual const std::vector<v1::Vertiport> &vertiports() const = 0;
    virtual const std::vector<v1::SlotRequest> &slotRequests() const = 0;
    virtual const std::vector<v1::ComplianceZone> &complianceZones() const = 0;
    virtual const std::vector<v1::SafetyRisk> &safetyRisks() const = 0;
    virtual int simulationMinutes() const = 0;

    virtual bool planMission(std::size_t index, const std::string &route, const std::string &profile) = 0;
    virtual bool bookMission(std::size_t index) = 0;
    virtual bool delayMission(std::size_t index) = 0;
    virtual bool assignGate(std::size_t index, const std::string &callSign) = 0;
    virtual bool startCharging(std::size_t index, const std::string &callSign) = 0;
    virtual bool decideSlot(std::size_t index, bool granted) = 0;
    virtual bool setBoundaryEnforcement(std::size_t index, bool enforced) = 0;
    virtual bool applySafetyMitigation(std::size_t index) = 0;
    virtual void advance() = 0;
    virtual void reset() = 0;
};

} // namespace atm::face::interfaces