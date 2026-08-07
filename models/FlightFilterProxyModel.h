#pragma once

#include <QSortFilterProxyModel>

class FlightFilterProxyModel final : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit FlightFilterProxyModel(QObject *parent = nullptr);

    void setQuery(const QString &query);
    int sourceRowForProxyRow(int proxyRow) const;
    int proxyRowForSourceRow(int sourceRow) const;

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_query;
};