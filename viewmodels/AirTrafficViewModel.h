#pragma once

#include "models/FlightListModel.h"

#include <QObject>
#include <QVariantMap>

class AirTrafficViewModel final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel *flights READ flights CONSTANT)
    Q_PROPERTY(int flightCount READ flightCount CONSTANT)
    Q_PROPERTY(int alertCount READ alertCount CONSTANT)
    Q_PROPERTY(QVariantMap selectedFlight READ selectedFlight NOTIFY selectedTrackChanged)
    Q_PROPERTY(int selectedTrack READ selectedTrack WRITE setSelectedTrack NOTIFY selectedTrackChanged)
    Q_PROPERTY(int rangeNm READ rangeNm WRITE setRangeNm NOTIFY rangeNmChanged)
    Q_PROPERTY(bool sweepEnabled READ sweepEnabled WRITE setSweepEnabled NOTIFY sweepEnabledChanged)
    Q_PROPERTY(bool weatherEnabled READ weatherEnabled WRITE setWeatherEnabled NOTIFY weatherEnabledChanged)
    Q_PROPERTY(bool routesEnabled READ routesEnabled WRITE setRoutesEnabled NOTIFY routesEnabledChanged)
    Q_PROPERTY(bool operational READ operational CONSTANT)
    Q_PROPERTY(bool separationAlertActive READ separationAlertActive NOTIFY separationAlertActiveChanged)

public:
    explicit AirTrafficViewModel(QObject *parent = nullptr);

    QAbstractItemModel *flights();
    int flightCount() const;
    int alertCount() const;
    QVariantMap selectedFlight() const;

    int selectedTrack() const;
    void setSelectedTrack(int selectedTrack);

    int rangeNm() const;
    void setRangeNm(int rangeNm);

    bool sweepEnabled() const;
    void setSweepEnabled(bool enabled);
    bool weatherEnabled() const;
    void setWeatherEnabled(bool enabled);
    bool routesEnabled() const;
    void setRoutesEnabled(bool enabled);
    bool operational() const;
    bool separationAlertActive() const;

    Q_INVOKABLE void decreaseRange();
    Q_INVOKABLE void increaseRange();
    Q_INVOKABLE void acknowledgeSeparationAlert();

signals:
    void selectedTrackChanged();
    void rangeNmChanged();
    void sweepEnabledChanged();
    void weatherEnabledChanged();
    void routesEnabledChanged();
    void separationAlertActiveChanged();

private:
    FlightListModel m_flights;
    int m_selectedTrack = 0;
    int m_rangeNm = 80;
    bool m_sweepEnabled = true;
    bool m_weatherEnabled = true;
    bool m_routesEnabled = true;
    bool m_separationAlertActive = true;
};