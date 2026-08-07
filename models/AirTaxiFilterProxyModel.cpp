#include "AirTaxiFilterProxyModel.h"

#include "AirTaxiListModel.h"

AirTaxiFilterProxyModel::AirTaxiFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
}

void AirTaxiFilterProxyModel::setQuery(const QString &query)
{
    const QString normalizedQuery = query.trimmed();
    if (m_query == normalizedQuery)
        return;

    m_query = normalizedQuery;
    invalidateFilter();
}

void AirTaxiFilterProxyModel::setAltitudeBand(const QString &altitudeBand)
{
    if (m_altitudeBand == altitudeBand)
        return;
    m_altitudeBand = altitudeBand;
    invalidateFilter();
}

void AirTaxiFilterProxyModel::setMissionPhase(const QString &missionPhase)
{
    if (m_missionPhase == missionPhase)
        return;
    m_missionPhase = missionPhase;
    invalidateFilter();
}

void AirTaxiFilterProxyModel::setSquawkCode(const QString &squawkCode)
{
    const QString normalizedCode = squawkCode.trimmed();
    if (m_squawkCode == normalizedCode)
        return;
    m_squawkCode = normalizedCode;
    invalidateFilter();
}

int AirTaxiFilterProxyModel::sourceRowForProxyRow(int proxyRow) const
{
    return mapToSource(index(proxyRow, 0)).row();
}

int AirTaxiFilterProxyModel::proxyRowForSourceRow(int sourceRow) const
{
    return mapFromSource(sourceModel()->index(sourceRow, 0)).row();
}

bool AirTaxiFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    const QString callSign = sourceModel()->data(sourceIndex, AirTaxiListModel::CallSignRole).toString();
    const QString route = sourceModel()->data(sourceIndex, AirTaxiListModel::RouteRole).toString();
    const QString level = sourceModel()->data(sourceIndex, AirTaxiListModel::LevelRole).toString();
    const QString phase = sourceModel()->data(sourceIndex, AirTaxiListModel::StateRole).toString();
    const QString squawk = sourceModel()->data(sourceIndex, AirTaxiListModel::SquawkRole).toString();
    const int altitudeFeet = level.section(QLatin1Char(' '), 0, 0).toInt();

    const bool queryMatches = m_query.isEmpty()
        || callSign.contains(m_query, Qt::CaseInsensitive)
        || route.contains(m_query, Qt::CaseInsensitive);
    const bool altitudeMatches = m_altitudeBand.isEmpty()
        || (m_altitudeBand == QStringLiteral("LOW") && altitudeFeet < 1000)
        || (m_altitudeBand == QStringLiteral("MID") && altitudeFeet >= 1000 && altitudeFeet <= 2000)
        || (m_altitudeBand == QStringLiteral("HIGH") && altitudeFeet > 2000);
    const bool phaseMatches = m_missionPhase.isEmpty()
        || phase.compare(m_missionPhase, Qt::CaseInsensitive) == 0;
    const bool squawkMatches = m_squawkCode.isEmpty()
        || squawk.startsWith(m_squawkCode, Qt::CaseInsensitive);
    return queryMatches && altitudeMatches && phaseMatches && squawkMatches;
}