#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace atm::face::contracts::v1 {

constexpr int kSurveillanceSchemaVersion = 1;

struct Track
{
    std::string callSign;
    std::string vehicleType;
    std::string squawk;
    double positionX = 0; // 0.0 to 1.0
    double positionY = 0; // 0.0 to 1.0
    int altitudeFt = 0;
    int speedKts = 0;
    int heading = 0;
    int trend = 0; // -1, 0, 1
    bool alert = false;
};

struct SurveillanceState
{
    int schemaVersion = kSurveillanceSchemaVersion;
    std::uint64_t timestamp = 0;
    std::vector<Track> tracks;
};

} // namespace atm::face::contracts::v1