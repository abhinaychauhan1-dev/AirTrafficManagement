#include "AppShellViewModel.h"

#include <QVariantMap>

AppShellViewModel::AppShellViewModel(QObject *parent)
    : QObject(parent)
    , m_modules{
          QVariantMap{
              {"label", "Live Radar View"},
              {"description", "Real-time map of aircraft moving through the monitored airspace."},
              {"availability", "LIVE"}},
          QVariantMap{
              {"label", "Flight & Traffic Simulation"},
              {"description", "Simulated traffic scenarios for testing incoming-aircraft handling."},
              {"availability", "SIMULATION"}},
          QVariantMap{
              {"label", "System Health & Power"},
              {"description", "System performance, power status, and hardware health monitoring."},
              {"availability", "PLANNED"},
              {"featureNumber", "02"},
              {"title", "BATTERY ENDURANCE & ALTERNATIVE LANDING LOCATION ENGINE"},
              {"summary", "Will calculate mission energy reserves continuously and rank reachable alternative landing locations under operational constraints."},
              {"capabilities", QStringList{"Energy reserve and degradation model", "Reachable ALL ranking", "Diversion recommendation workflow"}}},
          QVariantMap{
              {"label", "Performance Stress Test"},
              {"description", "Heavy aircraft-load scenarios that measure software limits and resilience."},
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