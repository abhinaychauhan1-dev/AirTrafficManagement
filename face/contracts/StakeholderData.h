#pragma once

#include <cstdint>
#include <string>

namespace atm::face::v1 {

inline constexpr std::uint16_t kSchemaVersion = 1;

enum class Stakeholder : std::uint8_t {
    System = 0,
    FleetOperator = 1,
    VertiportOperator = 2,
    AnspPsu = 3,
    UrbanAuthority = 4
};

struct Mission {
    std::string callSign;
    std::string route;
    std::string profile;
    std::string departure;
    int healthPercent = 0;
    std::string status;
};

struct Vertiport {
    std::string name;
    int gates = 0;
    int freeGates = 0;
    int chargers = 0;
    int freeChargers = 0;
    int passengerQueue = 0;
    int turnaroundMinutes = 0;
    std::string status;
};

struct SlotRequest {
    std::string requestId;
    std::string callSign;
    std::string corridor;
    std::string desiredTime;
    std::string status;
};

struct ComplianceZone {
    std::string name;
    std::string track;
    int overflightCap = 0;
    int currentOverflights = 0;
    int noiseDba = 0;
    bool enforced = false;
    std::string status;
};

struct SimulationEvent {
    std::uint16_t schemaVersion = kSchemaVersion;
    std::uint64_t sequence = 0;
    int simulationMinutes = 0;
    Stakeholder source = Stakeholder::System;
    std::string message;
};

} // namespace atm::face::v1