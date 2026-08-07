#pragma once

#include "face/interfaces/IEventTransport.h"
#include "face/interfaces/IStakeholderSimulation.h"

#include <string>
#include <vector>

namespace atm::face::components {

class StakeholderSimulationComponent final : public interfaces::IStakeholderSimulation
{
public:
    explicit StakeholderSimulationComponent(interfaces::IEventTransport &transport);

    const std::vector<v1::Mission> &missions() const override;
    const std::vector<v1::Vertiport> &vertiports() const override;
    const std::vector<v1::SlotRequest> &slotRequests() const override;
    const std::vector<v1::ComplianceZone> &complianceZones() const override;
    int simulationMinutes() const override;

    bool planMission(std::size_t index, const std::string &route, const std::string &profile) override;
    bool bookMission(std::size_t index) override;
    bool delayMission(std::size_t index) override;
    bool assignGate(std::size_t index, const std::string &callSign) override;
    bool startCharging(std::size_t index, const std::string &callSign) override;
    bool decideSlot(std::size_t index, bool granted) override;
    bool setBoundaryEnforcement(std::size_t index, bool enforced) override;
    void advance() override;
    void reset() override;

private:
    void publish(v1::Stakeholder source, const std::string &message);
    void updateMissionStatus(const std::string &callSign, const std::string &status);

    interfaces::IEventTransport &m_transport;
    std::vector<v1::Mission> m_missions;
    std::vector<v1::Vertiport> m_vertiports;
    std::vector<v1::SlotRequest> m_slotRequests;
    std::vector<v1::ComplianceZone> m_complianceZones;
    int m_minutes = 8 * 60 + 15;
};

} // namespace atm::face::components