# DO-178C-Aligned Software Assurance Plan

## 1. Purpose and Status

This project applies selected DO-178C software-assurance principles to improve determinism, traceability, robustness, and verification readiness. It is not approved or certified airborne software. No Design Assurance Level (DAL) has been assigned, and no certification credit is claimed.

A certification applicant must coordinate the system safety assessment, intended function, certification basis, DAL, plans, standards, lifecycle data, tool qualification, and authority involvement with the appropriate certification authority.

## 2. Current Software Boundary

The assured demonstration boundary contains:

- Portable operational logic under `face/components`.
- Versioned boundary data under `face/contracts`.
- Abstract interfaces under `face/interfaces`.
- Qt adaptation, model validation, and status propagation under `adapters`, `models`, and `viewmodels`.

The QML presentation, Qt runtime, Windows platform, MinGW toolchain, MQTT broker, and simulated data sources are unqualified development or demonstration elements. They must not be treated as airborne display or control components without additional lifecycle evidence and platform qualification.

## 3. Planning Assumptions

- Software level: TBD by system safety assessment.
- Intended function: ground-based UAM traffic-management demonstration.
- Target hardware and operating system: not baselined.
- Compiler, linker, Qt tools, and static-analysis tools: not qualified.
- Requirements, design, code, and verification baselines: managed in source control but not under an approved certification configuration-management process.
- Verification independence: not established.

Any change to these assumptions requires an impact analysis and an update to this plan.

## 4. Development Principles

1. Operational behavior is implemented in portable components, not QML.
2. Boundary contracts are versioned and validated before use.
3. Invalid input is rejected atomically; partially updated operational state is prohibited.
4. The last known good state is retained after rejected surveillance input.
5. State transitions use bounded values and deterministic control flow.
6. Expected invalid input is handled without exceptions or process termination.
7. Resource counters remain within declared physical capacities.
8. Each software requirement traces to implementation and verification evidence.
9. Derived requirements are identified and reviewed with the system-safety process.
10. Warnings, problem reports, and verification anomalies are resolved or formally dispositioned before a baseline is released.

## 5. Software Requirements and Traceability

| ID | Software requirement | Implementation | Current verification evidence |
| --- | --- | --- | --- |
| SWR-SUR-001 | The surveillance boundary shall accept only the declared schema version. | `AirTaxiListModel::updateFromState` | Source review; Debug build |
| SWR-SUR-002 | The surveillance boundary shall reject frames with more than 256 tracks. | `isValidSurveillanceState` | Source review; Debug build |
| SWR-SUR-003 | Each accepted track shall have a unique, nonempty call sign and a four-digit squawk. | `isValidSurveillanceState` | Source review; Debug build |
| SWR-SUR-004 | Accepted positions, altitude, speed, heading, and trend shall remain within documented UAM bounds. | `isValidSurveillanceState` | Source review; Debug build |
| SWR-SUR-005 | Rejected surveillance input shall not partially mutate the displayed model. | `AirTaxiListModel::updateFromState` | Source review |
| SWR-SUR-006 | Rejected surveillance input shall retain the last known good state and indicate degraded operation. | `QtSurveillanceAdapter::onTick`, `AirTrafficViewModel::onSurveillanceInputRejected` | Source review; application smoke check |
| SWR-MIS-001 | Mission planning shall reject empty, oversized, nonprintable, or structurally invalid route/profile input. | `StakeholderSimulationComponent::planMission` | Source review; Debug build |
| SWR-MIS-002 | Mission-delay time handling shall validate `HH:mm` without throwing an exception. | `addMinutes`, `StakeholderSimulationComponent::delayMission` | Source review; Debug build |
| SWR-MIS-003 | A mission shall not consume a gate or charger repeatedly for the same active allocation. | `assignGate`, `startCharging` | Source review; Debug build |
| SWR-COM-001 | Compliance enforcement shall affect only slots assigned to the enforced corridor. | `setBoundaryEnforcement`, `decideSlot` | Source review; Debug build |
| SWR-UI-001 | Filter changes shall keep the selected surveillance track valid and visible when a matching track exists. | `AirTrafficViewModel::reconcileFilteredSelection` | Source review; Debug build |
| SWR-INT-001 | Each operational intent shall retain a stable identity and monotonic revision across lifecycle mutations. | `SlotRequest`, `StakeholderSimulationComponent` | Source review; Debug build |
| SWR-INT-002 | Intent acceptance shall reject invalid or conflicting corridor, time, and altitude volumes. | `isValidOperationalVolume`, `decideSlot` | Source review; Debug build |
| SWR-INT-003 | Correlated transport events shall reject stale or duplicate entity revisions. | `MqttEventTransport::store` | Source review; Debug build |
| SWR-INT-004 | The operator shall be shown intent identity, revision, lifecycle, volume, status, and conflict reason. | `QtStakeholderSimulationAdapter::slotRequests`, `MultiStakeholderView.qml` | Source review; QML lint |
| SWR-SMS-001 | Each safety risk shall retain stable identity, revision, owner, mitigation, and bounded initial/residual assessment values. | `SafetyRisk`, `StakeholderSimulationComponent` | Source review; Debug build |
| SWR-SMS-002 | A safety mitigation shall invoke its linked operational control before entering monitoring. | `StakeholderSimulationComponent::applySafetyMitigation` | Source review; Debug build |
| SWR-SMS-003 | Mitigation withdrawal and verified recovery shall produce explicit reassessment or closure with correlated evidence. | `setBoundaryEnforcement`, `advance`, `publish` | Source review; Debug build |
| SWR-SMS-004 | The operator shall be shown risk identity, status, owner, mitigation, and initial/residual classification. | `QtStakeholderSimulationAdapter::safetyRisks`, `MultiStakeholderView.qml` | Source review; QML lint |

The bounds in SWR-SUR-002 and SWR-SUR-004 are derived requirements. They require confirmation against system capacity, sensor-interface, and airspace requirements before certification use.

## 6. Coding Standard

Production C++ changes shall follow these rules:

- Use ISO C++17 features supported by the baselined compiler.
- Initialize all state and use explicit fixed-width types at external contracts where representation matters.
- Validate indexes, sizes, schema identifiers, enumerated ranges, numeric finiteness, and units at boundaries.
- Avoid exception-dependent normal control flow in operational components.
- Avoid hidden dynamic state, recursion, unbounded loops, and order-dependent container behavior in operational paths.
- Keep portable components independent of Qt, the operating system, networking, and presentation code.
- Make state changes only after all preconditions are validated.
- Treat compiler warnings as review items; do not suppress a warning without documented rationale.
- Keep requirement identifiers in the traceability matrix rather than scattering unverifiable claims through code comments.

## 7. Verification Strategy

Certification-oriented verification remains required and shall include:

1. Reviews of requirements for accuracy, consistency, verifiability, and conformity.
2. Reviews of architecture and source code against requirements and coding standards.
3. Requirements-based normal-range, boundary, robustness, and failure-response tests.
4. Interface tests for every versioned contract and invalid-data class.
5. Data-coupling and control-coupling analysis across components and adapters.
6. Structural coverage analysis to the level required by the assigned DAL, including MC/DC when applicable.
7. Object-code-to-source trace analysis when compiler-generated behavior is not directly traceable.
8. Stack, timing, memory, resource-capacity, and worst-case execution analyses on the target platform.
9. Verification independence appropriate to the assigned DAL.
10. Regression verification and impact analysis for every baseline change.

Project tests were not created or executed as part of this change. The current evidence is compilation, QML linting from prior integration work, source review, and application startup smoke checking; this is not sufficient for certification credit.

## 8. Configuration Management

A controlled baseline shall identify at minimum:

- Source revision and all submodule revisions.
- Requirements, design, interface-control, coding-standard, and verification documents.
- Compiler, linker, qmake, Qt, and platform versions and options.
- Generated resource and meta-object inputs.
- Build procedures and reproducible build outputs.
- Verification procedures, results, coverage data, review records, and anomaly dispositions.

Generated files under `build/` are outputs and shall not be edited as source.

## 9. Quality Assurance and Problem Reporting

Each problem report shall record the observed behavior, affected requirement, safety and DAL impact, root cause, correction, affected baselines, regression scope, verification result, and approval. Unresolved anomalies must be evaluated for operational and certification impact before release.

## 10. Remaining Certification Work

The following major objectives are open:

- Establish system requirements, safety assessment, intended function, and DAL.
- Create and approve the software planning documents and lifecycle standards.
- Complete high-level and low-level requirements for all operational behavior.
- Establish full bidirectional traceability from system requirements through object code and verification results.
- Add requirements-based verification procedures and results; obtain the required structural coverage.
- Baseline target hardware, operating system, networking, timing, resource limits, and failure behavior.
- Qualify or provide service history/verification evidence for applicable tools and COTS software.
- Establish verification independence, configuration audits, quality-assurance records, and certification-authority coordination.
- Produce the final software accomplishment summary and approved configuration index.

Until these objectives are completed and accepted by the certification authority, the application remains a DO-178C-aligned demonstration only.
