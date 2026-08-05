#include "AirTrafficViewModel.h"

#include <QtGlobal>

AirTrafficViewModel::AirTrafficViewModel(QObject *parent)
    : QObject(parent)
    , m_flights(this)
{
}

QAbstractItemModel *AirTrafficViewModel::flights()
{
    return &m_flights;
}

int AirTrafficViewModel::flightCount() const
{
    return m_flights.rowCount();
}

int AirTrafficViewModel::alertCount() const
{
    return m_flights.alertCount();
}

QVariantMap AirTrafficViewModel::selectedFlight() const
{
    return m_flights.flightAt(m_selectedTrack);
}

int AirTrafficViewModel::selectedTrack() const
{
    return m_selectedTrack;
}

void AirTrafficViewModel::setSelectedTrack(int selectedTrack)
{
    const int boundedTrack = qBound(0, selectedTrack, m_flights.rowCount() - 1);
    if (m_selectedTrack == boundedTrack)
        return;

    m_selectedTrack = boundedTrack;
    emit selectedTrackChanged();
}

int AirTrafficViewModel::rangeNm() const
{
    return m_rangeNm;
}

void AirTrafficViewModel::setRangeNm(int rangeNm)
{
    const int boundedRange = qBound(20, rangeNm, 160);
    if (m_rangeNm == boundedRange)
        return;

    m_rangeNm = boundedRange;
    emit rangeNmChanged();
}

bool AirTrafficViewModel::sweepEnabled() const
{
    return m_sweepEnabled;
}

void AirTrafficViewModel::setSweepEnabled(bool enabled)
{
    if (m_sweepEnabled == enabled)
        return;
    m_sweepEnabled = enabled;
    emit sweepEnabledChanged();
}

bool AirTrafficViewModel::weatherEnabled() const
{
    return m_weatherEnabled;
}

void AirTrafficViewModel::setWeatherEnabled(bool enabled)
{
    if (m_weatherEnabled == enabled)
        return;
    m_weatherEnabled = enabled;
    emit weatherEnabledChanged();
}

bool AirTrafficViewModel::routesEnabled() const
{
    return m_routesEnabled;
}

void AirTrafficViewModel::setRoutesEnabled(bool enabled)
{
    if (m_routesEnabled == enabled)
        return;
    m_routesEnabled = enabled;
    emit routesEnabledChanged();
}

bool AirTrafficViewModel::operational() const
{
    return true;
}

bool AirTrafficViewModel::separationAlertActive() const
{
    return m_separationAlertActive;
}

void AirTrafficViewModel::decreaseRange()
{
    setRangeNm(m_rangeNm - 20);
}

void AirTrafficViewModel::increaseRange()
{
    setRangeNm(m_rangeNm + 20);
}

void AirTrafficViewModel::acknowledgeSeparationAlert()
{
    if (!m_separationAlertActive)
        return;
    m_separationAlertActive = false;
    emit separationAlertActiveChanged();
}