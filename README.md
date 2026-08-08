# Air Taxi Traffic Management (ATTM) System

A desktop-based Air Taxi Traffic Management and simulation application built using **C++** and the **Qt framework**. This project is designed to model, monitor, and simulate urban air mobility (UAM) operations, tracking trajectories, and airspace management workflows.

---

## Features

* **Real-Time Simulation:** Simulate air taxi movement, routing, and radar tracking.
* **Interactive UI:** Built with Qt Quick for responsive airspace and mission visualization.
* **Conflict Detection:** Monitor separation alerts and corridor compliance.
* **Mission Management:** Coordinate active missions, vertiports, UTM slots, and operational events.

---

## Tech Stack

* **Language:** C++17
* **Framework:** Qt 6 with Qt Quick and Qt Quick Controls 2
* **Build System:** qmake

---

## Runtime Configuration

The application runs with its built-in Delhi demonstration simulation when no MQTT broker is available. The demonstration data and operator labels contain Delhi-specific vertiports and corridors; deploying another operating area requires replacing that configured simulation data.

MQTT event exchange is optional and is configured before launch with environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `ATTM_MQTT_HOST` | `localhost` | Broker hostname |
| `ATTM_MQTT_PORT` | `1883` (`8883` with TLS) | Broker port |
| `ATTM_MQTT_TOPIC` | `attm/events` | Publish and subscribe topic |
| `ATTM_MQTT_USERNAME` | empty | Optional broker username |
| `ATTM_MQTT_PASSWORD` | empty | Optional broker password |
| `ATTM_MQTT_TLS` | `false` | Enable TLS with `true` or `1` |

The defaults are intended only for local development. Networked deployment must use an authenticated broker and TLS on trusted infrastructure; do not expose unencrypted MQTT to an untrusted network.

---

## Software Assurance

The project applies selected DO-178C-aligned principles for deterministic behavior, defensive boundary validation, requirements traceability, and verification readiness. It also applies an ASTM F3548-21-aligned interoperability profile for versioned operational intent and selected ICAO Doc 9859-aligned safety-management practices for hazard ownership, risk assessment, mitigation, and assurance monitoring. It is not certified airborne software, an ASTM-conformant USS implementation, or an approved Safety Management System.

- [DO-178C-aligned assurance plan](docs/DO178C_ASSURANCE_PLAN.md)
- [ASTM F3548-21-aligned interoperability profile](docs/ASTM_F3548_ALIGNMENT.md)
- [ICAO Doc 9859-aligned safety management plan](docs/ICAO_9859_SMS_ALIGNMENT.md)

---

## Project Structure
```text
AirTaxiTrafficManagement/
|-- adapters/                    # Qt adapters for transport and FACE components
|-- docs/                        # Architecture documentation
|-- face/                        # Portable contracts, interfaces, and components
|-- models/                      # Air taxi list and filter models
|-- presentation/                # QML application views and controls
|-- viewmodels/                  # Application and surveillance view models
|-- AirTaxiTrafficManagement.pro # Active qmake project
|-- main.cpp                     # Application composition root
|-- qml.qrc                      # QML resources
`-- README.md
