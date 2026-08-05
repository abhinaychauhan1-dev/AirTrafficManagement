#include "InMemoryEventTransport.h"

#include <utility>

namespace atm::face::transport {

InMemoryEventTransport::InMemoryEventTransport(std::size_t capacity)
    : m_capacity(capacity)
{
}

void InMemoryEventTransport::publish(v1::SimulationEvent event)
{
    event.sequence = m_nextSequence++;
    m_events.insert(m_events.begin(), std::move(event));
    if (m_events.size() > m_capacity)
        m_events.resize(m_capacity);
}

const std::vector<v1::SimulationEvent> &InMemoryEventTransport::events() const
{
    return m_events;
}

void InMemoryEventTransport::clear()
{
    m_events.clear();
}

} // namespace atm::face::transport