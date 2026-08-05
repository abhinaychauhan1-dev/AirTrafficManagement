# Air Traffic Management (ATM) System

A desktop-based Air Traffic Management and simulation application built using **C++** and the **Qt framework**. This project is designed to model, monitor, and simulate air traffic control operations, tracking trajectories, and airspace management workflows.

---

## 🚀 Features

* **Real-Time Simulation:** Simulate aircraft movement, routing, and radar tracking.
* **Interactive UI:** Built with Qt Widgets / Qt Quick for responsive, high-performance visualization of airspace maps.
* **Conflict Detection:** (If applicable) Algorithms to monitor proximity and prevent route collisions.
* **Flight Data Management:** Load, manage, and log flight plans, waypoint coordinates, and telemetry data.

---

## 🛠️ Tech Stack

* **Language:** C++ (C++11 or higher)
* **Framework:** Qt 5 / Qt 6
* **Build System:** CMake / qmake

---

## 📂 Project Structure

```text
AirTrafficManagement/
│
├── 📁 src/                 # Source files (.cpp, .h)
│   ├── 📁 ui/              # User interface components and windows
│   ├── 📁 core/            # Business logic (Aircraft, Radar, Simulation engine)
│   └── 📁 models/          # Data models for flight lists and maps
│
├── 📁 resources/           # Icons, maps, configuration files, and assets
├── 📁 tests/               # Unit and integration tests
├── CMakeLists.txt          # CMake configuration file (or AirTrafficManagement.pro)
└── README.md               # Project documentation
