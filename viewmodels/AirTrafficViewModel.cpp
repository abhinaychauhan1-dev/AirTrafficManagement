#include "AirTrafficViewModel.h"

#include <QDateTime>
#include <QtGlobal>

namespace {

constexpr int kMinimumRangeNm = 5;
constexpr int kMaximumRangeNm = 40;
constexpr int kRangeStepNm = 5;

QVariantMap point(qreal x, qreal y)
{
    return {{QStringLiteral("x"), x}, {QStringLiteral("y"), y}};
}

} // namespace

AirTrafficViewModel::AirTrafficViewModel(QObject *parent)
    : QObject(parent)
    , m_airTaxis(this)
    , m_filteredAirTaxis(this)
{
    m_filteredAirTaxis.setSourceModel(&m_airTaxis);
    m_clockTimer.setInterval(1000);
    connect(&m_clockTimer, &QTimer::timeout, this, &AirTrafficViewModel::clockChanged);
    m_clockTimer.start();

    m_currentAlertCallSign = alertAirTaxi().value(QStringLiteral("callSign")).toString();
}

QAbstractItemModel *AirTrafficViewModel::filteredAirTaxis()
{
    return &m_filteredAirTaxis;
}

AirTaxiListModel &AirTrafficViewModel::airTaxiListModel()
{
    return m_airTaxis;
}

void AirTrafficViewModel::setAirTaxiFilter(const QString &filter)
{
    if (m_airTaxiFilter == filter)
        return;
    m_airTaxiFilter = filter;
    m_filteredAirTaxis.setQuery(filter);
    reconcileFilteredSelection();
    emit airTaxiFilterChanged();
}

void AirTrafficViewModel::setAltitudeFilter(const QString &filter)
{
    if (m_altitudeFilter == filter)
        return;
    m_altitudeFilter = filter;
    m_filteredAirTaxis.setAltitudeBand(filter);
    reconcileFilteredSelection();
    emit airTaxiFilterChanged();
}

void AirTrafficViewModel::setPhaseFilter(const QString &filter)
{
    if (m_phaseFilter == filter)
        return;
    m_phaseFilter = filter;
    m_filteredAirTaxis.setMissionPhase(filter);
    reconcileFilteredSelection();
    emit airTaxiFilterChanged();
}

void AirTrafficViewModel::setSquawkFilter(const QString &filter)
{
    if (m_squawkFilter == filter)
        return;
    m_squawkFilter = filter;
    m_filteredAirTaxis.setSquawkCode(filter);
    reconcileFilteredSelection();
    emit airTaxiFilterChanged();
}

void AirTrafficViewModel::clearQuickFilters()
{
    setAltitudeFilter({});
    setPhaseFilter({});
    setSquawkFilter({});
}

int AirTrafficViewModel::filteredAirTaxiCount() const
{
    return m_filteredAirTaxis.rowCount();
}

int AirTrafficViewModel::airTaxiCount() const
{
    return m_airTaxis.rowCount();
}

int AirTrafficViewModel::alertCount() const
{
    return m_airTaxis.alertCount();
}

QVariantMap AirTrafficViewModel::alertAirTaxi() const
{
    return m_airTaxis.alertAirTaxi();
}

QVariantMap AirTrafficViewModel::selectedAirTaxi() const
{
    return m_airTaxis.airTaxiAt(m_selectedTrack);
}

int AirTrafficViewModel::selectedFilteredTrack() const
{
    return m_filteredAirTaxis.proxyRowForSourceRow(m_selectedTrack);
}

void AirTrafficViewModel::reconcileFilteredSelection()
{
    if (m_filteredAirTaxis.rowCount() > 0 && selectedFilteredTrack() < 0)
        setSelectedTrack(m_filteredAirTaxis.sourceRowForProxyRow(0));
}

void AirTrafficViewModel::setSelectedTrack(int selectedTrack)
{
    const int boundedTrack = qBound(0, selectedTrack, m_airTaxis.rowCount() - 1);
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
    return m_surveillanceInputValid;
}

bool AirTrafficViewModel::separationAlertActive() const
{
    return alertCount() > 0 && !m_alertAcknowledged;
}

QVariantList AirTrafficViewModel::operationalFacts() const
{
    const QVariantMap weather = weatherSummary();
    return {
        QVariantMap{{"label", "UAM ZONE"}, {"value", "DELHI-C"}},
        QVariantMap{{"label", "ACTIVE PADS"}, {"value", "14 / 16"}},
        QVariantMap{{"label", "QNH"}, {"value", weather.value("qnh").toString() + QStringLiteral(" hPa")}}
    };
}

QVariantMap AirTrafficViewModel::activeVertiport() const
{
    return {{"name", "IGI V2"}, {"pad", "P3"}, {"heading", 281}, {"status", "OPEN"}};
}

QVariantMap AirTrafficViewModel::weatherSummary() const
{
    const int windDirection = 278 + (m_surveillanceTick / 5) % 9;
    const int qnh = 1008 + (m_surveillanceTick / 30) % 2;
    return {
        {"station", "DELHI UAM NET"}, {"temperature", 31}, {"cloud", "URBAN CEILING 3,000 FT"},
        {"windDirection", windDirection}, {"wind", "12 KT  G18"}, {"visibility", "6 KM"},
        {"qnh", QString::number(qnh)}, {"dewPoint", 24}, {"advisory", "GUST CAUTION  •  IGI V2 / AERO V7 CORRIDOR"}
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

QVariantList AirTrafficViewModel::selectedAirTaxiMetrics() const
{
    const QVariantMap airTaxi = selectedAirTaxi();
    return {
        QVariantMap{{"label", "SQUAWK"}, {"value", airTaxi.value("squawk")}},
        QVariantMap{{"label", "ALTITUDE"}, {"value", airTaxi.value("level")}},
        QVariantMap{{"label", "AIR SPEED"}, {"value", airTaxi.value("speed").toString() + QStringLiteral(" KT")}},
        QVariantMap{{"label", "BATTERY"}, {"value", airTaxi.value("battery").toString() + QStringLiteral("%")}},
        QVariantMap{{"label", "HEADING"}, {"value", airTaxi.value("heading").toString() + QStringLiteral("°")}},
        QVariantMap{{"label", "EVTOL"}, {"value", airTaxi.value("vehicleType")}}
    };
}

QVariantList AirTrafficViewModel::sectorLoads() const
{
    int west = 0;
    int east = 0;
    int north = 0;
    int south = 0;
    for (int row = 0; row < m_airTaxis.rowCount(); ++row) {
        const QVariantMap airTaxi = m_airTaxis.airTaxiAt(row);
        airTaxi.value("positionX").toReal() < .5 ? ++west : ++east;
        airTaxi.value("positionY").toReal() < .5 ? ++north : ++south;
    }
    const qreal total = qMax(1, m_airTaxis.rowCount());
    return {
        QVariantMap{{"name", "UAM WEST"}, {"trackCount", west}, {"load", west / total}, {"category", "primary"}},
        QVariantMap{{"name", "UAM EAST"}, {"trackCount", east}, {"load", east / total}, {"category", "primary"}},
        QVariantMap{{"name", "CITY NORTH"}, {"trackCount", north}, {"load", north / total}, {"category", "secondary"}},
        QVariantMap{{"name", "CITY SOUTH"}, {"trackCount", south}, {"load", south / total}, {"category", "secondary"}}
    };
}

QVariantMap AirTrafficViewModel::datalinkStatus() const
{
    return {{"online", true}, {"label", "UTM LINK ONLINE"}, {"messageCount", 12 + m_surveillanceTick / 15}};
}

QVariantMap AirTrafficViewModel::separationAlert() const
{
    return {
        {"code", "STCA"},
        {"title", QStringLiteral("%1  •  CORRIDOR SEPARATION ALERT").arg(alertAirTaxi().value("callSign").toString())},
        {"instruction", "REVIEW AIR TAXI ROUTE AND COORDINATE CORRIDOR RESOLUTION"}
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

QString AirTrafficViewModel::radarId() const { return QStringLiteral("UAM SURVEILLANCE 01"); }
QString AirTrafficViewModel::updateRate() const { return QStringLiteral("1.0s"); }
QString AirTrafficViewModel::adsbCoverage() const { return QStringLiteral("99.8%"); }
QString AirTrafficViewModel::controllerPosition() const { return QStringLiteral("UAM OPS: PRIYA S.  -  DESK: DEL-C04"); }
QString AirTrafficViewModel::dataStatusText() const
{
    return m_surveillanceInputValid ? QStringLiteral("LIVE AIR TAXI FEED")
                                    : QStringLiteral("INPUT REJECTED / LAST KNOWN GOOD");
}
qreal AirTrafficViewModel::viewCenterX() const { return m_viewCenterX; }
qreal AirTrafficViewModel::viewCenterY() const { return m_viewCenterY; }
QString AirTrafficViewModel::istTime() const
{
    return QDateTime::currentDateTimeUtc().addSecs(19800)
        .toString(QStringLiteral("HH:mm:ss"));
}

QString AirTrafficViewModel::istDate() const
{
    return QDateTime::currentDateTimeUtc().addSecs(19800)
        .toString(QStringLiteral("dd MMM yyyy 'IST'"))
        .toUpper();
}

void AirTrafficViewModel::selectFilteredTrack(int proxyIndex)
{
    const int sourceRow = m_filteredAirTaxis.sourceRowForProxyRow(proxyIndex);
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
    const QVariantMap airTaxi = selectedAirTaxi();
    m_viewCenterX = airTaxi.value(QStringLiteral("positionX")).toReal();
    m_viewCenterY = airTaxi.value(QStringLiteral("positionY")).toReal();
    setRangeNm(qMin(m_rangeNm, 40));
    emit viewportChanged();
}

void AirTrafficViewModel::resetRadarView()
{
    m_viewCenterX = .5;
    m_viewCenterY = .51;
    setRangeNm(20);
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

void AirTrafficViewModel::onSurveillanceUpdate()
{
    ++m_surveillanceTick;
    if (!m_surveillanceInputValid) {
        m_surveillanceInputValid = true;
        emit operationalChanged();
    }
    const QString alertCallSign = alertAirTaxi().value(QStringLiteral("callSign")).toString();
    if (alertCallSign.isEmpty()) {
        m_alertAcknowledged = false;
        m_currentAlertCallSign.clear();
    } else if (alertCallSign != m_currentAlertCallSign) {
        m_alertAcknowledged = false;
        m_currentAlertCallSign = alertCallSign;
    }
    reconcileFilteredSelection();
    emit surveillanceChanged();
    emit selectedTrackChanged();
    emit airTaxiFilterChanged();
    emit separationAlertActiveChanged();
}

void AirTrafficViewModel::onSurveillanceInputRejected()
{
    if (!m_surveillanceInputValid)
        return;
    m_surveillanceInputValid = false;
    emit operationalChanged();
}

void AirTrafficViewModel::focusFilteredTrack(int proxyIndex)
{
    const int sourceRow = m_filteredAirTaxis.sourceRowForProxyRow(proxyIndex);
    if (sourceRow >= 0)
        focusTrack(sourceRow);
}