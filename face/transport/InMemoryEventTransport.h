#pragma once

#include "face/interfaces/IEventTransport.h"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace atm::face::transport {

class InMemoryEventTransport final : public interfaces::IEventTransport
{
public:
    explicit InMemoryEventTransport(std::size_t capacity = 8);

    void publish(v1::SimulationEvent event) override;
    const std::vector<v1::SimulationEvent> &events() const override;
    void clear() override;

private:
    std::size_t m_capacity;
    std::uint64_t m_nextSequence = 1;
    std::vector<v1::SimulationEvent> m_events;
};

} // namespace atm::face::transport