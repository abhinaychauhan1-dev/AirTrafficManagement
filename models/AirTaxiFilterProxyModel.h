#pragma once

#include <QSortFilterProxyModel>

class AirTaxiFilterProxyModel final : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit AirTaxiFilterProxyModel(QObject *parent = nullptr);

    void setQuery(const QString &query);
    void setAltitudeBand(const QString &altitudeBand);
    void setMissionPhase(const QString &missionPhase);
    void setSquawkCode(const QString &squawkCode);
    int sourceRowForProxyRow(int proxyRow) const;
    int proxyRowForSourceRow(int sourceRow) const;

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_query;
    QString m_altitudeBand;
    QString m_missionPhase;
    QString m_squawkCode;
};