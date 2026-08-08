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

enum class OperationalIntentState : std::uint8_t {
    Draft = 0,
    Submitted = 1,
    Accepted = 2,
    Activated = 3,
    Closed = 4,
    Nonconforming = 5,
    Contingent = 6,
    Rejected = 7,
    Conflict = 8
};

enum class SafetyRiskStatus : std::uint8_t {
    MitigationRequired = 0,
    Monitoring = 1,
    Closed = 2
};

enum class SafetyMitigationAction : std::uint8_t {
    BlockDispatch = 0,
    EnforceBoundary = 1
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
    int chargingMinutes = 0;
    std::string chargingCallSign;
    std::string turnaroundCallSign;
};

struct SlotRequest {
    std::string requestId;
    std::string operationalIntentId;
    std::uint32_t revision = 1;
    std::string callSign;
    std::string corridor;
    std::string desiredTime;
    int startMinute = 0;
    int endMinute = 0;
    int minimumAltitudeFt = 0;
    int maximumAltitudeFt = 0;
    OperationalIntentState state = OperationalIntentState::Draft;
    std::string status;
    std::string conflictReason;
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

struct SafetyRisk {
    std::string riskId;
    std::uint32_t revision = 1;
    std::string hazard;
    std::string consequence;
    std::string linkedCallSign;
    std::string linkedEntity;
    std::string owner;
    std::string mitigation;
    int initialLikelihood = 1;
    int initialSeverity = 1;
    int residualLikelihood = 1;
    int residualSeverity = 1;
    SafetyRiskStatus status = SafetyRiskStatus::MitigationRequired;
    SafetyMitigationAction action = SafetyMitigationAction::BlockDispatch;
};

struct SimulationEvent {
    std::uint16_t schemaVersion = kSchemaVersion;
    std::uint64_t sequence = 0;
    int simulationMinutes = 0;
    Stakeholder source = Stakeholder::System;
    std::string message;
    std::string correlationId;
    std::uint32_t entityVersion = 0;
};

} // namespace atm::face::v1