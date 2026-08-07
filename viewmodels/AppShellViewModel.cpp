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
              {"label", "Active Taxi Missions"},
              {"description", "Current eVTOL missions with their assigned vertiports, UTM slots, and compliance status."},
              {"availability", "SIMULATION"}},
          QVariantMap{
              {"label", "Hub & Ground Operations"},
              {"description", "Live landing-pad, turnaround, queue, charging, and localized hub weather operations."},
              {"availability", "LIVE"}},
          QVariantMap{
              {"label", "Performance Stress Test"},
              {"description", "High-density air-taxi demand scenarios that measure network limits and resilience."},
              {"availability", "PLANNED"},
              {"featureNumber", "03"},
              {"title", "DISRUPTION AND STRESS-TESTING SCENARIOS"},
              {"summary", "Will inject deterministic and stochastic disruptions to measure network resilience and operator response quality."},
              {"capabilities", QStringList{"Weather and infrastructure failures", "Demand surge scenarios", "Recovery KPI comparison"}}},
          QVariantMap{
              {"label", "System Check & Compliance"},
              {"description", "Diagnostic checks against operational standards and compliance requirements."},
              {"availability", "PLANNED"},
              {"featureNumber", "04"},
              {"title", "CONFORMANCE AND TRAJECTORY TRACKING MODULE"},
              {"summary", "Will compare live tracks with cleared four-dimensional trajectories and issue escalating conformance alerts."},
              {"capabilities", QStringList{"4D trajectory correlation", "Lateral and vertical deviation alerts", "Controller resolution workflow"}}}
      }
{
}

QStringList AppShellViewModel::moduleLabels() const
{
    QStringList labels;
    for (const QVariant &module : m_modules)
        labels.append(module.toMap().value(QStringLiteral("label")).toString());
    return labels;
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