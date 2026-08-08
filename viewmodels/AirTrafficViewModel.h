#pragma once

#include "models/AirTaxiFilterProxyModel.h"
#include "models/AirTaxiListModel.h"

#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class AirTrafficViewModel final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel *filteredAirTaxis READ filteredAirTaxis CONSTANT)
    Q_PROPERTY(int filteredAirTaxiCount READ filteredAirTaxiCount NOTIFY airTaxiFilterChanged)
    Q_PROPERTY(int airTaxiCount READ airTaxiCount CONSTANT)
    Q_PROPERTY(int alertCount READ alertCount NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap alertAirTaxi READ alertAirTaxi NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap selectedAirTaxi READ selectedAirTaxi NOTIFY surveillanceChanged)
    Q_PROPERTY(int selectedFilteredTrack READ selectedFilteredTrack NOTIFY selectedTrackChanged)
    Q_PROPERTY(int rangeNm READ rangeNm NOTIFY rangeNmChanged)
    Q_PROPERTY(bool atMinimumRange READ atMinimumRange NOTIFY rangeNmChanged)
    Q_PROPERTY(bool atMaximumRange READ atMaximumRange NOTIFY rangeNmChanged)
    Q_PROPERTY(bool sweepEnabled READ sweepEnabled NOTIFY sweepEnabledChanged)
    Q_PROPERTY(bool weatherEnabled READ weatherEnabled NOTIFY weatherEnabledChanged)
    Q_PROPERTY(bool routesEnabled READ routesEnabled NOTIFY routesEnabledChanged)
    Q_PROPERTY(bool operational READ operational NOTIFY operationalChanged)
    Q_PROPERTY(bool separationAlertActive READ separationAlertActive NOTIFY separationAlertActiveChanged)
    Q_PROPERTY(QVariantList operationalFacts READ operationalFacts NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap activeVertiport READ activeVertiport CONSTANT)
    Q_PROPERTY(QVariantMap weatherSummary READ weatherSummary NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantList weatherMetrics READ weatherMetrics NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantList selectedAirTaxiMetrics READ selectedAirTaxiMetrics NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantList sectorLoads READ sectorLoads NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap datalinkStatus READ datalinkStatus NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap separationAlert READ separationAlert NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantList boundaryPolyline READ boundaryPolyline CONSTANT)
    Q_PROPERTY(QVariantList routeOverlays READ routeOverlays CONSTANT)
    Q_PROPERTY(QVariantList weatherCells READ weatherCells CONSTANT)
    Q_PROPERTY(QString radarId READ radarId CONSTANT)
    Q_PROPERTY(QString updateRate READ updateRate CONSTANT)
    Q_PROPERTY(QString adsbCoverage READ adsbCoverage CONSTANT)
    Q_PROPERTY(QString controllerPosition READ controllerPosition CONSTANT)
    Q_PROPERTY(QString dataStatusText READ dataStatusText NOTIFY operationalChanged)
    Q_PROPERTY(qreal viewCenterX READ viewCenterX NOTIFY viewportChanged)
    Q_PROPERTY(qreal viewCenterY READ viewCenterY NOTIFY viewportChanged)
    Q_PROPERTY(QString istTime READ istTime NOTIFY clockChanged)
    Q_PROPERTY(QString istDate READ istDate NOTIFY clockChanged)

public:
    explicit AirTrafficViewModel(QObject *parent = nullptr);

    QAbstractItemModel *filteredAirTaxis();
    AirTaxiListModel &airTaxiListModel();
    Q_INVOKABLE void setAirTaxiFilter(const QString &filter);
    Q_INVOKABLE void setAltitudeFilter(const QString &filter);
    Q_INVOKABLE void setPhaseFilter(const QString &filter);
    Q_INVOKABLE void setSquawkFilter(const QString &filter);
    Q_INVOKABLE void clearQuickFilters();
    int filteredAirTaxiCount() const;
    int airTaxiCount() const;
    int alertCount() const;
    QVariantMap alertAirTaxi() const;
    QVariantMap selectedAirTaxi() const;

    int selectedFilteredTrack() const;

    int rangeNm() const;
    bool atMinimumRange() const;
    bool atMaximumRange() const;

    bool sweepEnabled() const;
    bool weatherEnabled() const;
    bool routesEnabled() const;
    bool operational() const;
    bool separationAlertActive() const;
    QVariantList operationalFacts() const;
    QVariantMap activeVertiport() const;
    QVariantMap weatherSummary() const;
    QVariantList weatherMetrics() const;
    QVariantList selectedAirTaxiMetrics() const;
    QVariantList sectorLoads() const;
    QVariantMap datalinkStatus() const;
    QVariantMap separationAlert() const;
    QVariantList boundaryPolyline() const;
    QVariantList routeOverlays() const;
    QVariantList weatherCells() const;
    QString radarId() const;
    QString updateRate() const;
    QString adsbCoverage() const;
    QString controllerPosition() const;
    QString dataStatusText() const;
    qreal viewCenterX() const;
    qreal viewCenterY() const;
    QString istTime() const;
    QString istDate() const;

    Q_INVOKABLE void selectFilteredTrack(int proxyIndex);
    Q_INVOKABLE void focusFilteredTrack(int proxyIndex);
    Q_INVOKABLE void decreaseRange();
    Q_INVOKABLE void increaseRange();
    Q_INVOKABLE void changeRangeBySteps(int steps);
    Q_INVOKABLE void resetRadarView();
    Q_INVOKABLE void toggleSweep();
    Q_INVOKABLE void toggleWeather();
    Q_INVOKABLE void toggleRoutes();
    Q_INVOKABLE void acknowledgeSeparationAlert();
    void onSurveillanceUpdate();
    void onSurveillanceInputRejected();

signals:
    void selectedTrackChanged();
    void airTaxiFilterChanged();
    void rangeNmChanged();
    void sweepEnabledChanged();
    void weatherEnabledChanged();
    void routesEnabledChanged();
    void separationAlertActiveChanged();
    void clockChanged();
    void surveillanceChanged();
    void viewportChanged();
    void operationalChanged();

private:
    void focusTrack(int sourceIndex);
    void reconcileFilteredSelection();
    void setSelectedTrack(int selectedTrack);
    void setRangeNm(int rangeNm);
    void setSweepEnabled(bool enabled);
    void setWeatherEnabled(bool enabled);
    void setRoutesEnabled(bool enabled);

    AirTaxiListModel m_airTaxis;
    AirTaxiFilterProxyModel m_filteredAirTaxis;
    QTimer m_clockTimer;
    QString m_airTaxiFilter;
    QString m_altitudeFilter;
    QString m_phaseFilter;
    QString m_squawkFilter;
    QString m_currentAlertCallSign;
    int m_selectedTrack = 0;
    int m_rangeNm = 20;
    int m_surveillanceTick = 0;
    qreal m_viewCenterX = .5;
    qreal m_viewCenterY = .51;
    bool m_sweepEnabled = true;
    bool m_weatherEnabled = true;
    bool m_routesEnabled = true;
    bool m_alertAcknowledged = false;
    bool m_surveillanceInputValid = true;
};