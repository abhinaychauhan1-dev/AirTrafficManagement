#include "SurveillanceComponent.h"

#include <algorithm>
#include <cmath>

namespace atm::face::components {

namespace {

struct AirTaxiPath
{
    double startX, startY, endX, endY;
};

const std::vector<AirTaxiPath> kPaths{
    {0.08, 0.82, 0.93, 0.24}, {0.12, 0.20, 0.90, 0.76}, {0.31, 0.93, 0.65, 0.10},
    {0.91, 0.88, 0.14, 0.12}, {0.85, 0.07, 0.15, 0.91}, {0.06, 0.51, 0.94, 0.52},
};

struct AirTaxiDefinition
{
    std::string callSign;
    std::string vehicleType;
    std::string squawk;
    int pathIndex;
    int initialAltitude;
    int speed;
    double startOffset;
};

const std::vector<AirTaxiDefinition> kAirTaxis{
    {"ATX201", "JOBY-S4", "3301", 0, 1200, 96, 0.0},
    {"SKY114", "ARCHER-M", "4123", 1, 1800, 82, 0.1},
    {"URB308", "VOLOCITY", "5510", 2, 2200, 104, 0.2},
    {"UAM420", "LILIUM-J", "1123", 3, 900, 74, 0.05},
    {"ECO512", "EVE-AIR", "7301", 4, 2600, 112, 0.15},
    {"ATX628", "JOBY-S4", "4462", 5, 700, 68, 0.25},
    {"SKY735", "ARCHER-M", "6211", 0, 1500, 88, 0.5},
    {"MED804", "VOLOCITY", "3170", 1, 2400, 118, 0.6},
    {"UAM916", "LILIUM-J", "2142", 2, 1100, 78, 0.7},
    {"ECO322", "EVE-AIR", "7701", 3, 1900, 102, 0.55},
    {"ATX447", "JOBY-S4", "1127", 4, 2100, 94, 0.65},
    {"SKY860", "ARCHER-M", "7301", 5, 1300, 86, 0.75},
};

constexpr int kTotalSteps = 1200;

} // namespace

SurveillanceComponent::SurveillanceComponent() { reset(); }

const contracts::v1::SurveillanceState &SurveillanceComponent::surveillanceState() const
{
    return m_state;
}

void SurveillanceComponent::advance()
{
    m_state.timestamp = (m_state.timestamp + 1) % kTotalSteps;
    for (auto &track : m_state.tracks) {
        const auto &definition = kAirTaxis[&track - &m_state.tracks[0]];
        const auto &path = kPaths[definition.pathIndex];

        const double progress = std::fmod(static_cast<double>(m_state.timestamp) / kTotalSteps + definition.startOffset, 1.0);
        track.positionX = path.startX + (path.endX - path.startX) * progress;
        track.positionY = path.startY + (path.endY - path.startY) * progress;

        const double dx = path.endX - path.startX;
        const double dy = path.endY - path.startY;
        track.heading = static_cast<int>(std::round(std::atan2(dx, -dy) * 180 / 3.14159265)) % 360;
        if (track.heading < 0)
            track.heading += 360;

        track.altitudeFt = definition.initialAltitude + static_cast<int>(std::sin(progress * 6.28) * 15);
        track.trend = static_cast<int>(std::round(std::cos(progress * 6.28)));

        // Simple separation conflict alert simulation
        if (track.callSign == "ATX201" && progress > 0.45 && progress < 0.55) {
            track.alert = true;
        } else {
            track.alert = false;
        }
    }
}

void SurveillanceComponent::reset()
{
    m_state.timestamp = 0;
    m_state.tracks.clear();
    m_state.tracks.reserve(kAirTaxis.size());
    for (const auto &definition : kAirTaxis) {
        contracts::v1::Track track;
        track.callSign = definition.callSign;
        track.vehicleType = definition.vehicleType;
        track.squawk = definition.squawk;
        track.speedKts = definition.speed;
        m_state.tracks.push_back(track);
    }
    // Initial advance to populate positions
    advance();
}

} // namespace atm::face::components