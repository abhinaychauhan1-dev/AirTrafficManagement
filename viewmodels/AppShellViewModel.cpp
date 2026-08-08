#include "AppShellViewModel.h"

#include <QVariantMap>

AppShellViewModel::AppShellViewModel(QObject *parent)
    : QObject(parent)
    , m_modules{
          QVariantMap{
              {"label", "Live Air Taxi Network"},
              {"description", "Real-time map of eVTOL air taxis moving between Delhi vertiports."},
              {"availability", "LIVE"}},
          QVariantMap{
              {"label", "Vehicle Telemetry (Diagnostics)"},
              {"description", "Live flight instruments, propulsion, energy, and vehicle health diagnostics."},
              {"availability", "LIVE"}},
          QVariantMap{
              {"label", "Hub & Ground Operations"},
              {"description", "Live landing-pad, turnaround, queue, charging, and localized hub weather operations."},
              {"availability", "LIVE"}},
          QVariantMap{
              {"label", "Active Taxi Missions"},
              {"description", "Current eVTOL missions with their assigned vertiports, UTM slots, and compliance status."},
              {"availability", "SIMULATION"}}
      }
{
}

QVariantList AppShellViewModel::modules() const { return m_modules; }

int AppShellViewModel::selectedModuleIndex() const { return m_selectedModuleIndex; }

void AppShellViewModel::selectModule(int index)
{
    if (index < 0 || index >= m_modules.size() || m_selectedModuleIndex == index)
        return;
    m_selectedModuleIndex = index;
    emit selectedModuleIndexChanged();
}