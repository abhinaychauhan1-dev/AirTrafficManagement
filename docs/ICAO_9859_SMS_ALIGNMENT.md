# ICAO Doc 9859-Aligned Safety Management Plan

## Status and Scope

This project applies selected safety-management principles described by ICAO Doc 9859, *Safety Management Manual*, to a ground-based air-taxi traffic-management demonstration. It is not an approved Safety Management System, an operational safety case, or evidence of compliance with any State safety programme or service-provider regulation.

The implemented safety register is a demonstration control. Its risk matrix, thresholds, owners, and mitigations require approval within the accountable organization's SMS before operational use.

## Safety Policy and Objectives

The demonstration policy is to identify operational hazards before dispatch or airspace authorization, assign an accountable owner, apply a traceable mitigation, monitor predicted residual risk, and retain revisioned evidence of each state change.

Defined demonstration responsibilities are:

- The fleet safety manager owns vehicle-readiness hazards and dispatch controls.
- The UTM duty manager owns corridor-capacity hazards and airspace mitigations.
- Operators apply mitigations through authorized local controls.
- Safety-risk changes are published as correlated, revisioned events.
- Safety-critical decisions remain subject to organizational approval, emergency-response planning, and regulatory oversight outside this application.

Emergency response, executive accountability, formal safety committees, occurrence-reporting protections, document approval, and coordination with external response organizations are not implemented by the application.

## Safety Risk Management

### Hazard identification

Each `SafetyRisk` record contains:

- A stable risk ID and monotonic revision.
- Hazard and credible consequence descriptions.
- A linked mission and operational entity.
- An accountable owner and explicit mitigation.
- Initial and predicted residual likelihood and severity.
- A lifecycle state of `MITIGATION REQUIRED`, `MONITORING`, or `CLOSED`.

The initial register identifies vehicle-health loss of margin and corridor-capacity exceedance. Additional hazards require a controlled reporting and review process; this demonstration does not infer a complete hazard inventory.

### Local demonstration matrix

Likelihood and severity use bounded integer values from 1 to 5. The local score is:

$$
R = L \times S
$$

The display bands are `LOW` for scores 1-7, `MEDIUM` for 8-14, and `HIGH` for 15-25. These thresholds are project-defined and are not asserted to be an ICAO-prescribed matrix or an organization's approved risk-acceptance policy.

Predicted residual risk is shown separately from initial risk. Applying a mitigation moves a risk to monitoring; it does not by itself constitute formal risk acceptance. Vehicle-health risk closes only after the simulated health threshold is restored. Removing corridor enforcement returns the linked risk to mitigation-required status.

### Operational controls

- Vehicle-health mitigation blocks dispatch while health is below 60 percent.
- Corridor-capacity mitigation enforces the linked boundary and holds affected intents.
- Mitigation application, withdrawal, monitoring, and closure increment the risk revision.
- Every mutation emits a correlated audit event using the risk ID and revision.
- Invalid risk indexes, closed risks, or missing linked entities are rejected without partial mutation.

## Safety Assurance

The operator view displays the current register for the selected mission, including owner, mitigation, initial risk, predicted residual risk, lifecycle, and revision. Existing activity records provide an observable audit trail for mitigation actions and closure criteria.

The following safety performance indicators are suitable for future controlled reporting:

- Number of risks requiring mitigation.
- Number of mitigations under monitoring.
- Time from hazard report to mitigation.
- Number of reopened or overdue risks.
- Repeat vehicle-readiness and corridor-capacity hazards.
- Rejected surveillance frames and operational-intent conflicts.

Before operational use, assurance must include independent review, data-quality monitoring, occurrence investigation, trend analysis, effectiveness verification, management-of-change assessment, internal audit, corrective-action tracking, and periodic management review. Predicted residual scores must not be treated as accepted without delegated approval and objective evidence.

## Management of Change

Changes to routes, operational volumes, capacity thresholds, vehicle-health thresholds, transport schemas, risk matrices, ownership, mitigations, or external service dependencies require documented safety-impact assessment. The assessment must identify affected hazards, assumptions, interfaces, procedures, training, verification evidence, and rollback or transition controls before release.

## Safety Promotion

The UI communicates risk state and ownership to operators, but it does not provide competency management. Deployment requires role-based training, recurrent training, safety communication, reporting channels, lessons-learned distribution, and confirmation that personnel understand authority limits and escalation procedures.

## Traceability

| ID | Safety-management requirement | Implementation |
| --- | --- | --- |
| SMS-HID-001 | A recorded hazard shall have stable identity, consequence, linked operation, owner, and mitigation. | `SafetyRisk`, `StakeholderSimulationComponent::reset` |
| SMS-SRA-001 | Initial and predicted residual risk shall retain bounded likelihood and severity values and remain distinguishable. | `SafetyRisk`, `QtStakeholderSimulationAdapter::safetyRisks` |
| SMS-MIT-001 | Applying a mitigation shall invoke the linked operational control and enter monitoring. | `StakeholderSimulationComponent::applySafetyMitigation` |
| SMS-ASR-001 | Mitigation withdrawal and closure shall update lifecycle, revision, and correlated evidence. | `setBoundaryEnforcement`, `advance`, `publish` |
| SMS-UI-001 | The operator shall see risk identity, revision, status, owner, mitigation, and initial/residual classification. | `QtStakeholderSimulationAdapter`, `MultiStakeholderView.qml` |

## Open SMS Work

- Obtain the applicable State and service-provider requirements and establish the approved SMS scope.
- Appoint the accountable executive and safety manager, with documented authorities and accountabilities.
- Establish confidential hazard and occurrence reporting, investigation, and protection processes.
- Approve the risk matrix, acceptance authorities, escalation criteria, and tolerability policy.
- Integrate authoritative telemetry, occurrence data, human-factors inputs, and external safety information.
- Establish emergency-response coordination and interfaces with operators, ANSPs, vertiports, authorities, and responders.
- Implement persistent records, access control, electronic approval, retention, audit history, and cybersecurity controls.
- Define safety performance objectives, indicators, alert levels, data quality, review cadence, and continuous-improvement governance.
- Complete management-of-change, training, communication, audit, independent assurance, and regulatory acceptance activities.

Only the responsible organization and aviation authorities can determine whether an SMS is acceptable for the intended operation.