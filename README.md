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

## Software Assurance

The project applies selected DO-178C-aligned principles for deterministic behavior, defensive boundary validation, requirements traceability, and verification readiness. It is not certified airborne software and does not claim certification credit. See [docs/DO178C_ASSURANCE_PLAN.md](docs/DO178C_ASSURANCE_PLAN.md) for scope, traced requirements, current evidence, and remaining certification work.

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
