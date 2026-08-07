#pragma once

#include "models/FlightFilterProxyModel.h"
#include "models/FlightListModel.h"

#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class AirTrafficViewModel final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel *flights READ flights CONSTANT)
    Q_PROPERTY(QAbstractItemModel *filteredFlights READ filteredFlights CONSTANT)
    Q_PROPERTY(QString flightFilter READ flightFilter WRITE setFlightFilter NOTIFY flightFilterChanged)
    Q_PROPERTY(int filteredFlightCount READ filteredFlightCount NOTIFY flightFilterChanged)
    Q_PROPERTY(int flightCount READ flightCount CONSTANT)
    Q_PROPERTY(int alertCount READ alertCount NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap alertFlight READ alertFlight NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap selectedFlight READ selectedFlight NOTIFY surveillanceChanged)
    Q_PROPERTY(int selectedTrack READ selectedTrack NOTIFY selectedTrackChanged)
    Q_PROPERTY(int selectedFilteredTrack READ selectedFilteredTrack NOTIFY selectedTrackChanged)
    Q_PROPERTY(int rangeNm READ rangeNm NOTIFY rangeNmChanged)
    Q_PROPERTY(int minimumRangeNm READ minimumRangeNm CONSTANT)
    Q_PROPERTY(int maximumRangeNm READ maximumRangeNm CONSTANT)
    Q_PROPERTY(bool atMinimumRange READ atMinimumRange NOTIFY rangeNmChanged)
    Q_PROPERTY(bool atMaximumRange READ atMaximumRange NOTIFY rangeNmChanged)
    Q_PROPERTY(bool sweepEnabled READ sweepEnabled NOTIFY sweepEnabledChanged)
    Q_PROPERTY(bool weatherEnabled READ weatherEnabled NOTIFY weatherEnabledChanged)
    Q_PROPERTY(bool routesEnabled READ routesEnabled NOTIFY routesEnabledChanged)
    Q_PROPERTY(bool operational READ operational CONSTANT)
    Q_PROPERTY(bool separationAlertActive READ separationAlertActive NOTIFY separationAlertActiveChanged)
    Q_PROPERTY(QVariantList operationalFacts READ operationalFacts NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantMap activeRunway READ activeRunway CONSTANT)
    Q_PROPERTY(QVariantMap weatherSummary READ weatherSummary NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantList weatherMetrics READ weatherMetrics NOTIFY surveillanceChanged)
    Q_PROPERTY(QVariantList selectedFlightMetrics READ selectedFlightMetrics NOTIFY surveillanceChanged)
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
    Q_PROPERTY(QString dataStatusText READ dataStatusText CONSTANT)
    Q_PROPERTY(QString lastUpdateTime READ lastUpdateTime NOTIFY surveillanceChanged)
    Q_PROPERTY(qreal viewCenterX READ viewCenterX NOTIFY viewportChanged)
    Q_PROPERTY(qreal viewCenterY READ viewCenterY NOTIFY viewportChanged)
    Q_PROPERTY(QString utcTime READ utcTime NOTIFY utcClockChanged)
    Q_PROPERTY(QString utcDate READ utcDate NOTIFY utcClockChanged)

public:
    explicit AirTrafficViewModel(QObject *parent = nullptr);

    QAbstractItemModel *flights();
    QAbstractItemModel *filteredFlights();
    QString flightFilter() const;
    Q_INVOKABLE void setFlightFilter(const QString &filter);
    int filteredFlightCount() const;
    int flightCount() const;
    int alertCount() const;
    QVariantMap alertFlight() const;
    QVariantMap selectedFlight() const;

    int selectedTrack() const;
    int selectedFilteredTrack() const;

    int rangeNm() const;
    int minimumRangeNm() const;
    int maximumRangeNm() const;
    bool atMinimumRange() const;
    bool atMaximumRange() const;

    bool sweepEnabled() const;
    bool weatherEnabled() const;
    bool routesEnabled() const;
    bool operational() const;
    bool separationAlertActive() const;
    QVariantList operationalFacts() const;
    QVariantMap activeRunway() const;
    QVariantMap weatherSummary() const;
    QVariantList weatherMetrics() const;
    QVariantList selectedFlightMetrics() const;
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
    QString lastUpdateTime() const;
    qreal viewCenterX() const;
    qreal viewCenterY() const;
    QString utcTime() const;
    QString utcDate() const;

    Q_INVOKABLE void selectTrack(int sourceIndex);
    Q_INVOKABLE void selectFilteredTrack(int proxyIndex);
    Q_INVOKABLE void decreaseRange();
    Q_INVOKABLE void increaseRange();
    Q_INVOKABLE void changeRangeBySteps(int steps);
    Q_INVOKABLE void focusTrack(int sourceIndex);
    Q_INVOKABLE void resetRadarView();
    Q_INVOKABLE void toggleSweep();
    Q_INVOKABLE void toggleWeather();
    Q_INVOKABLE void toggleRoutes();
    Q_INVOKABLE void acknowledgeSeparationAlert();
    Q_INVOKABLE void advanceSurveillance();

signals:
    void selectedTrackChanged();
    void flightFilterChanged();
    void rangeNmChanged();
    void sweepEnabledChanged();
    void weatherEnabledChanged();
    void routesEnabledChanged();
    void separationAlertActiveChanged();
    void utcClockChanged();
    void surveillanceChanged();
    void viewportChanged();

private:
    void setSelectedTrack(int selectedTrack);
    void setRangeNm(int rangeNm);
    void setSweepEnabled(bool enabled);
    void setWeatherEnabled(bool enabled);
    void setRoutesEnabled(bool enabled);

    FlightListModel m_flights;
    FlightFilterProxyModel m_filteredFlights;
    QTimer m_clockTimer;
    QTimer m_surveillanceTimer;
    QString m_flightFilter;
    QString m_currentAlertCallSign;
    int m_selectedTrack = 0;
    int m_rangeNm = 80;
    int m_surveillanceTick = 0;
    qreal m_viewCenterX = .5;
    qreal m_viewCenterY = .51;
    bool m_sweepEnabled = true;
    bool m_weatherEnabled = true;
    bool m_routesEnabled = true;
    bool m_alertAcknowledged = false;
};