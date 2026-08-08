# ASTM F3548-21-Aligned Interoperability Profile

## Status and Applicability

This project applies selected interoperability principles associated with ASTM F3548-21, *Standard Specification for UAS Traffic Management (UTM) UAS Service Supplier (USS) Interoperability*. It does not implement the normative ASTM API or claim ASTM conformance.

The application models urban air-taxi and eVTOL operations. F3548-21 addresses UAS/USS interoperability; applicability to passenger-carrying air taxis must be established by the responsible aviation authorities, system safety process, and deployment concept. The implementation below is therefore an architectural alignment profile only.

## Implemented Profile

### Operational intent identity and revision

Every slot request carries:

- A stable `operationalIntentId`.
- A monotonically increasing `revision`.
- A call sign and corridor association.
- A bounded time interval and altitude interval.
- An explicit lifecycle state.
- A human-readable coordination status and conflict reason.

Correlated event messages carry the operational-intent ID and entity revision. The MQTT transport rejects zero, duplicate, or stale revisions for a known correlated entity.

### Lifecycle management

The local lifecycle is:

```text
DRAFT -> SUBMITTED -> ACCEPTED -> ACTIVATED -> CLOSED
                    -> REJECTED
                    -> CONFLICT
```

`NONCONFORMING` and `CONTINGENT` are represented in the contract for future conformance-monitoring and off-nominal workflows. The local names are not asserted to be the normative ASTM wire enumeration.

Slot decisions are accepted only while an intent is `SUBMITTED` and its operational window has not elapsed. Undecided draft or submitted intents transition to `REJECTED / EXPIRED` when their window closes, preventing obsolete intent data from remaining actionable.

Planning, booking, delay, constraint enforcement, strategic decisions, activation, and closure increment the operational-intent revision and publish correlated audit events.

### Four-dimensional operational volume

The demonstration volume consists of:

- A named corridor as a coarse horizontal volume reference.
- Inclusive operational context with a half-open time interval `[start, end)`.
- A half-open altitude interval `[minimum, maximum)` in feet.

A volume is rejected before acceptance when its identity, corridor, time bounds, or altitude bounds are invalid. Corridor names are simulation references, not certified geospatial polygons.

### Strategic coordination

An intent cannot be accepted when either condition applies:

1. An enforced compliance constraint has reached its configured capacity for the same corridor.
2. Another coordinated intent occupies the same corridor with overlapping time and altitude intervals.

Conflict results include a machine-readable lifecycle state, stable conflicting-intent reference in `conflictReason`, a mission status update, and a correlated audit event.

When a capacity constraint is enforced after an intent has activated, the operation transitions to `CONTINGENT` rather than being treated as a preflight denial. Releasing that exact constraint returns an in-window operation to `ACTIVATED`; an operation whose window has elapsed closes with review required. Every transition increments the intent revision and emits a correlated event.

### Transport integrity

The MQTT event envelope includes:

- Schema version.
- Monotonic transport sequence.
- Simulation time.
- Source role.
- Message.
- Correlation ID.
- Entity revision.

Inbound events are rejected for invalid schema, sequence, time, role, message bounds, correlation bounds, zero correlated revision, or a stale/duplicate entity revision. MQTT/TLS configuration alone does not provide USS identity assurance or authorization.

### Operator presentation

The UTM slot view displays operational-intent ID, revision, lifecycle, corridor, time window, altitude band, decision status, and conflict reason. Activity records display correlation and revision when present.

## Traceability

| ID | Requirement | Implementation |
| --- | --- | --- |
| INT-ID-001 | Each operational intent shall have a stable ID and monotonic revision. | `SlotRequest`, `StakeholderSimulationComponent` |
| INT-LCM-001 | Intent mutations shall produce explicit lifecycle transitions and correlated audit events. | `planMission`, `bookMission`, `delayMission`, `decideSlot`, `advance` |
| INT-VOL-001 | An accepted intent shall have valid bounded time and altitude intervals and a horizontal corridor reference. | `isValidOperationalVolume` |
| INT-SCD-001 | Acceptance shall reject overlapping coordinated volumes in the same corridor. | `timeWindowsOverlap`, `altitudeBandsOverlap`, `decideSlot` |
| INT-CNS-001 | Active corridor constraints shall prevent acceptance and identify the reason. | `decideSlot`, `setBoundaryEnforcement` |
| INT-TIM-001 | Decisions shall apply only to submitted, unexpired intents; undecided intents shall expire explicitly. | `decideSlot`, `advance`, `QtStakeholderSimulationAdapter::slotRequests` |
| INT-CNT-001 | A constraint imposed on an active operation shall produce a revisioned contingent transition and explicit recovery or closure. | `setBoundaryEnforcement`, `advance` |
| INT-TRN-001 | Correlated transport events shall reject stale or duplicate entity revisions. | `MqttEventTransport::store` |
| INT-UI-001 | Coordination identity, lifecycle, volume, status, and conflict reason shall be visible to the operator. | `QtStakeholderSimulationAdapter::slotRequests`, `MultiStakeholderView.qml` |

## Open Conformance Work

The following capabilities are not implemented and are required before any conformance assessment:

- The licensed normative ASTM F3548 data model, API operations, field semantics, error model, and protocol behavior.
- Discovery and Synchronization Service interactions, subscriptions, notifications, and multi-USS synchronization.
- Cryptographic USS identity, mutual authentication, authorization, key management, and trust governance.
- Certified geospatial operational volumes, reference systems, time standards, tolerances, and authoritative constraints.
- Distributed race handling, idempotency across process restart, persistence, recovery, and network-partition behavior.
- Conformance monitoring that transitions operations to nonconforming and contingent states from authoritative telemetry.
- Off-nominal coordination, priority handling, emergency operations, and applicable authority workflows.
- Service availability, latency, performance, scalability, cybersecurity, logging retention, and independent interoperability verification.
- Assessment of F3548 applicability to the air-taxi concept of operations and integration with applicable national regulations.

Only a licensed copy of the selected ASTM edition and an approved compliance process can define normative conformance criteria.
