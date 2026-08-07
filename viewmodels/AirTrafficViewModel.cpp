#include "AirTrafficViewModel.h"

#include <QDateTime>
#include <QtGlobal>

namespace {

constexpr int kMinimumRangeNm = 20;
constexpr int kMaximumRangeNm = 160;
constexpr int kRangeStepNm = 20;

QVariantMap point(qreal x, qreal y)
{
    return {{QStringLiteral("x"), x}, {QStringLiteral("y"), y}};
}

} // namespace

AirTrafficViewModel::AirTrafficViewModel(QObject *parent)
    : QObject(parent)
    , m_flights(this)
    , m_filteredFlights(this)
{
    m_filteredFlights.setSourceModel(&m_flights);
    m_clockTimer.setInterval(1000);
    connect(&m_clockTimer, &QTimer::timeout, this, &AirTrafficViewModel::utcClockChanged);
    m_clockTimer.start();

    m_currentAlertCallSign = alertFlight().value(QStringLiteral("callSign")).toString();
    m_surveillanceTimer.setInterval(1000);
    connect(&m_surveillanceTimer, &QTimer::timeout, this, &AirTrafficViewModel::advanceSurveillance);
    m_surveillanceTimer.start();
}

QAbstractItemModel *AirTrafficViewModel::flights()
{
    return &m_flights;
}

QAbstractItemModel *AirTrafficViewModel::filteredFlights()
{
    return &m_filteredFlights;
}

QString AirTrafficViewModel::flightFilter() const
{
    return m_flightFilter;
}

void AirTrafficViewModel::setFlightFilter(const QString &filter)
{
    if (m_flightFilter == filter)
        return;
    m_flightFilter = filter;
    m_filteredFlights.setQuery(filter);
    if (m_filteredFlights.rowCount() > 0 && selectedFilteredTrack() < 0)
        setSelectedTrack(m_filteredFlights.sourceRowForProxyRow(0));
    emit flightFilterChanged();
    emit selectedTrackChanged();
}

int AirTrafficViewModel::filteredFlightCount() const
{
    return m_filteredFlights.rowCount();
}

int AirTrafficViewModel::flightCount() const
{
    return m_flights.rowCount();
}

int AirTrafficViewModel::alertCount() const
{
    return m_flights.alertCount();
}

QVariantMap AirTrafficViewModel::alertFlight() const
{
    return m_flights.alertFlight();
}

QVariantMap AirTrafficViewModel::selectedFlight() const
{
    return m_flights.flightAt(m_selectedTrack);
}

int AirTrafficViewModel::selectedTrack() const
{
    return m_selectedTrack;
}

int AirTrafficViewModel::selectedFilteredTrack() const
{
    return m_filteredFlights.proxyRowForSourceRow(m_selectedTrack);
}

void AirTrafficViewModel::setSelectedTrack(int selectedTrack)
{
    const int boundedTrack = qBound(0, selectedTrack, m_flights.rowCount() - 1);
    if (m_selectedTrack == boundedTrack)
        return;

    m_selectedTrack = boundedTrack;
    emit selectedTrackChanged();
    emit surveillanceChanged();
}

int AirTrafficViewModel::rangeNm() const
{
    return m_rangeNm;
}

void AirTrafficViewModel::setRangeNm(int rangeNm)
{
    const int boundedRange = qBound(kMinimumRangeNm, rangeNm, kMaximumRangeNm);
    if (m_rangeNm == boundedRange)
        return;

    m_rangeNm = boundedRange;
    emit rangeNmChanged();
}

int AirTrafficViewModel::minimumRangeNm() const { return kMinimumRangeNm; }
int AirTrafficViewModel::maximumRangeNm() const { return kMaximumRangeNm; }
bool AirTrafficViewModel::atMinimumRange() const { return m_rangeNm == kMinimumRangeNm; }
bool AirTrafficViewModel::atMaximumRange() const { return m_rangeNm == kMaximumRangeNm; }

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
    return alertCount() > 0 && !m_alertAcknowledged;
}

QVariantList AirTrafficViewModel::operationalFacts() const
{
    const QVariantMap weather = weatherSummary();
    return {
        QVariantMap{{"label", "SECTOR"}, {"value", "DLC-W"}},
        QVariantMap{{"label", "FREQUENCY"}, {"value", "128.35"}},
        QVariantMap{{"label", "QNH"}, {"value", weather.value("qnh").toString() + QStringLiteral(" hPa")}}
    };
}

QVariantMap AirTrafficViewModel::activeRunway() const
{
    return {{"airport", "VIDP"}, {"runway", "28"}, {"heading", 281}, {"ils", "110.3"}};
}

QVariantMap AirTrafficViewModel::weatherSummary() const
{
    const int windDirection = 278 + (m_surveillanceTick / 5) % 9;
    const int qnh = 1008 + (m_surveillanceTick / 30) % 2;
    return {
        {"station", "VIDP"}, {"temperature", 31}, {"cloud", "FEW 3,000 FT"},
        {"windDirection", windDirection}, {"wind", "12 KT  G18"}, {"visibility", "6 KM"},
        {"qnh", QString::number(qnh)}, {"dewPoint", 24}, {"advisory", "TEMPO TSRA  •  CB NW OF FIELD"}
    };
}

QVariantList AirTrafficViewModel::weatherMetrics() const
{
    const QVariantMap weather = weatherSummary();
    return {
        QVariantMap{{"label", "VIS"}, {"value", weather.value("visibility")}},
        QVariantMap{{"label", "QNH"}, {"value", weather.value("qnh")}},
        QVariantMap{{"label", "DEW"}, {"value", weather.value("dewPoint").toString() + QStringLiteral("°C")}}
    };
}

QVariantList AirTrafficViewModel::selectedFlightMetrics() const
{
    const QVariantMap flight = selectedFlight();
    return {
        QVariantMap{{"label", "SQUAWK"}, {"value", flight.value("squawk")}},
        QVariantMap{{"label", "CLEARED"}, {"value", flight.value("level")}},
        QVariantMap{{"label", "GROUND SPEED"}, {"value", flight.value("speed").toString() + QStringLiteral(" KT")}},
        QVariantMap{{"label", "TREND"}, {"value", flight.value("trend")}},
        QVariantMap{{"label", "HEADING"}, {"value", flight.value("heading").toString() + QStringLiteral("°")}},
        QVariantMap{{"label", "AIRCRAFT"}, {"value", flight.value("aircraftType")}}
    };
}

QVariantList AirTrafficViewModel::sectorLoads() const
{
    int west = 0;
    int east = 0;
    int north = 0;
    int south = 0;
    for (int row = 0; row < m_flights.rowCount(); ++row) {
        const QVariantMap flight = m_flights.flightAt(row);
        flight.value("positionX").toReal() < .5 ? ++west : ++east;
        flight.value("positionY").toReal() < .5 ? ++north : ++south;
    }
    const qreal total = qMax(1, m_flights.rowCount());
    return {
        QVariantMap{{"name", "DLC-W"}, {"trackCount", west}, {"load", west / total}, {"category", "primary"}},
        QVariantMap{{"name", "DLC-E"}, {"trackCount", east}, {"load", east / total}, {"category", "primary"}},
        QVariantMap{{"name", "TMA-N"}, {"trackCount", north}, {"load", north / total}, {"category", "secondary"}},
        QVariantMap{{"name", "TMA-S"}, {"trackCount", south}, {"load", south / total}, {"category", "secondary"}}
    };
}

QVariantMap AirTrafficViewModel::datalinkStatus() const
{
    return {{"online", true}, {"label", "CPDLC ONLINE"}, {"messageCount", 12 + m_surveillanceTick / 15}};
}

QVariantMap AirTrafficViewModel::separationAlert() const
{
    return {
        {"code", "STCA"},
        {"title", QStringLiteral("%1  •  SEPARATION CONFLICT").arg(alertFlight().value("callSign").toString())},
        {"instruction", "REVIEW CONFLICT TRACK AND COORDINATE RESOLUTION"}
    };
}

QVariantList AirTrafficViewModel::boundaryPolyline() const
{
    return {point(.08, .60), point(.17, .48), point(.28, .43), point(.38, .28),
            point(.52, .31), point(.64, .19), point(.76, .30), point(.88, .25)};
}

QVariantList AirTrafficViewModel::routeOverlays() const
{
    return {
        QVariant::fromValue(QVariantList{point(.08, .82), point(.32, .58), point(.53, .48), point(.93, .24)}),
        QVariant::fromValue(QVariantList{point(.12, .20), point(.34, .38), point(.56, .51), point(.90, .76)}),
        QVariant::fromValue(QVariantList{point(.31, .93), point(.43, .64), point(.52, .51), point(.65, .10)})
    };
}

QVariantList AirTrafficViewModel::weatherCells() const
{
    return {
        QVariantMap{{"x", .28}, {"y", .66}, {"radius", .10}, {"color", "#385f31"}},
        QVariantMap{{"x", .30}, {"y", .65}, {"radius", .065}, {"color", "#7f7b25"}},
        QVariantMap{{"x", .74}, {"y", .33}, {"radius", .09}, {"color", "#305b38"}},
        QVariantMap{{"x", .76}, {"y", .34}, {"radius", .045}, {"color", "#976f22"}}
    };
}

QString AirTrafficViewModel::radarId() const { return QStringLiteral("RADAR 01"); }
QString AirTrafficViewModel::updateRate() const { return QStringLiteral("1.0s"); }
QString AirTrafficViewModel::adsbCoverage() const { return QStringLiteral("99.8%"); }
QString AirTrafficViewModel::controllerPosition() const { return QStringLiteral("CTRL: PRIYA S.  -  POSITION: DWC-04"); }
QString AirTrafficViewModel::dataStatusText() const { return QStringLiteral("SIMULATED SURVEILLANCE"); }
QString AirTrafficViewModel::lastUpdateTime() const { return utcTime(); }
qreal AirTrafficViewModel::viewCenterX() const { return m_viewCenterX; }
qreal AirTrafficViewModel::viewCenterY() const { return m_viewCenterY; }
QString AirTrafficViewModel::utcTime() const { return QDateTime::currentDateTimeUtc().toString(QStringLiteral("HH:mm:ss")); }
QString AirTrafficViewModel::utcDate() const { return QDateTime::currentDateTimeUtc().toString(QStringLiteral("dd MMM yyyy 'UTC'")).toUpper(); }

void AirTrafficViewModel::selectTrack(int sourceIndex)
{
    if (m_filteredFlights.proxyRowForSourceRow(sourceIndex) < 0)
        setFlightFilter(QString());
    setSelectedTrack(sourceIndex);
}

void AirTrafficViewModel::selectFilteredTrack(int proxyIndex)
{
    const int sourceRow = m_filteredFlights.sourceRowForProxyRow(proxyIndex);
    if (sourceRow >= 0)
        setSelectedTrack(sourceRow);
}

void AirTrafficViewModel::decreaseRange()
{
    changeRangeBySteps(-1);
}

void AirTrafficViewModel::increaseRange()
{
    changeRangeBySteps(1);
}

void AirTrafficViewModel::changeRangeBySteps(int steps)
{
    setRangeNm(m_rangeNm + steps * kRangeStepNm);
}

void AirTrafficViewModel::focusTrack(int sourceIndex)
{
    setSelectedTrack(sourceIndex);
    const QVariantMap flight = selectedFlight();
    m_viewCenterX = flight.value(QStringLiteral("positionX")).toReal();
    m_viewCenterY = flight.value(QStringLiteral("positionY")).toReal();
    setRangeNm(qMin(m_rangeNm, 40));
    emit viewportChanged();
}

void AirTrafficViewModel::resetRadarView()
{
    m_viewCenterX = .5;
    m_viewCenterY = .51;
    setRangeNm(80);
    emit viewportChanged();
}

void AirTrafficViewModel::toggleSweep() { setSweepEnabled(!m_sweepEnabled); }
void AirTrafficViewModel::toggleWeather() { setWeatherEnabled(!m_weatherEnabled); }
void AirTrafficViewModel::toggleRoutes() { setRoutesEnabled(!m_routesEnabled); }

void AirTrafficViewModel::acknowledgeSeparationAlert()
{
    if (!separationAlertActive())
        return;
    m_alertAcknowledged = true;
    emit separationAlertActiveChanged();
}

void AirTrafficViewModel::advanceSurveillance()
{
    const bool alertWasActive = separationAlertActive();
    ++m_surveillanceTick;
    m_flights.advanceOneSecond(m_surveillanceTick);

    const QString alertCallSign = alertFlight().value(QStringLiteral("callSign")).toString();
    if (alertCallSign.isEmpty()) {
        m_alertAcknowledged = false;
        m_currentAlertCallSign.clear();
    } else if (alertCallSign != m_currentAlertCallSign) {
        m_alertAcknowledged = false;
        m_currentAlertCallSign = alertCallSign;
    }

    emit surveillanceChanged();
    if (alertWasActive != separationAlertActive())
        emit separationAlertActiveChanged();
}