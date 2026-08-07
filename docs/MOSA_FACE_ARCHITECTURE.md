# MOSA/FACE-Aligned Architecture

## Scope

This project applies Modular Open Systems Approach (MOSA) principles and FACE-style technical boundaries. It is not a claim of FACE conformance or certification. Formal conformance requires selection of a FACE Technical Standard edition, an applicable conformance profile, approved data-model artifacts, and verification with the relevant FACE conformance process and toolchain.

## Dependency Direction

```text
QML views
    -> QtStakeholderSimulationAdapter
        -> IStakeholderSimulation / IEventTransport
            <- StakeholderSimulationComponent
            <- MqttEventTransport (production)
            <- InMemoryEventTransport (tests)

main.cpp selects and connects concrete implementations.
```

Dependencies point toward versioned contracts and abstract interfaces. Portable components never include Qt, QML, operating-system, or presentation headers.

## FACE Segment Mapping

| Project area | FACE-style responsibility |
| --- | --- |
| `face/contracts` | Versioned shared data model used at component boundaries |
| `face/interfaces` | Public Unit of Conformance and Transport Services contracts |
| `face/components` | Portable Components Segment business behavior |
| `face/transport` | Local Transport Services Segment implementation |
| `adapters` | Platform-specific Qt presentation and timing adapter |
| `main.cpp` | Composition root that selects replaceable implementations |
| `presentation` | QML views only; no operational business rules |

## MQTT transport and offline operation

Production uses MQTT 3.1.1 for versioned stakeholder events. The client reconnects automatically,
subscribes to the configured topic, and switches the application to the built-in simulation whenever
the broker is unavailable. Configure it with environment variables before launch:

| Variable | Default | Purpose |
|---|---|---|
| `ATTM_MQTT_HOST` | `localhost` | Broker hostname |
| `ATTM_MQTT_PORT` | `1883` (`8883` with TLS) | Broker port |
| `ATTM_MQTT_TOPIC` | `attm/events` | Publish and subscribe topic |
| `ATTM_MQTT_USERNAME` | empty | Optional username |
| `ATTM_MQTT_PASSWORD` | empty | Optional password |
| `ATTM_MQTT_TLS` | `false` | Set to `true` for TLS certificate validation |

Windows, Qt event-loop, and rendering services act as the current Operating System/Platform-Specific Services environment. External sensors, persistence, and network gateways should be added behind new interfaces rather than called from portable components.

## MOSA Rules

1. New operational modules are separate Units of Conformance behind narrow abstract interfaces.
2. Boundary data is defined in a versioned namespace under `face/contracts`; fields and explicit enum values are append-only within a schema version.
3. Modules communicate through transport interfaces. They do not reference another module's concrete class.
4. Concrete transport, platform, and component choices are made only in the composition root.
5. Portable components use ISO C++17 and the standard library only.
6. Each interface has behavior and contract tests that run without QML.
7. Generated build outputs are not architecture sources and must not be edited.

## Extension Pattern

The Battery/ALL, Stress Testing, and Conformance modules should each add:

1. Versioned request, response, state, and event contracts.
2. A public interface in `face/interfaces`.
3. A Qt-free implementation in `face/components`.
4. Transport publication/subscription through an `IEventTransport` implementation.
5. A Qt adapter only when data must cross into QML.
6. Composition and configuration in `main.cpp`.

This permits a local in-memory transport to be replaced by a qualified FACE Transport Services implementation without changing portable business logic or QML workflows.

## Remaining Formal-Conformance Work

- Select and record the target FACE Technical Standard edition and conformance profile.
- Produce FACE Data Architecture model artifacts and generated data types.
- Replace or qualify the local transport against the selected FACE Transport Services APIs.
- Establish portability evidence for the selected Operating System Segment profile.
- Add lifecycle, health management, configuration, security, and error-reporting contracts required by the deployment environment.
- Run the official conformance verification process for each submitted Unit of Conformance.