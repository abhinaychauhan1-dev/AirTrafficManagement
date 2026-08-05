#pragma once

#include "face/contracts/StakeholderData.h"

#include <vector>

namespace atm::face::interfaces {

class IEventTransport
{
public:
    virtual ~IEventTransport() = default;

    virtual void publish(v1::SimulationEvent event) = 0;
    virtual const std::vector<v1::SimulationEvent> &events() const = 0;
    virtual void clear() = 0;
};

} // namespace atm::face::interfaces