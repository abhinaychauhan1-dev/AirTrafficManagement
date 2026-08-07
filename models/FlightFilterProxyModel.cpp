#include "FlightFilterProxyModel.h"

#include "FlightListModel.h"

FlightFilterProxyModel::FlightFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
}

void FlightFilterProxyModel::setQuery(const QString &query)
{
    const QString normalizedQuery = query.trimmed();
    if (m_query == normalizedQuery)
        return;

    m_query = normalizedQuery;
    invalidateFilter();
}

int FlightFilterProxyModel::sourceRowForProxyRow(int proxyRow) const
{
    return mapToSource(index(proxyRow, 0)).row();
}

int FlightFilterProxyModel::proxyRowForSourceRow(int sourceRow) const
{
    return mapFromSource(sourceModel()->index(sourceRow, 0)).row();
}

bool FlightFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_query.isEmpty())
        return true;

    const QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    const QString callSign = sourceModel()->data(sourceIndex, FlightListModel::CallSignRole).toString();
    const QString route = sourceModel()->data(sourceIndex, FlightListModel::RouteRole).toString();
    return callSign.contains(m_query, Qt::CaseInsensitive)
        || route.contains(m_query, Qt::CaseInsensitive);
}