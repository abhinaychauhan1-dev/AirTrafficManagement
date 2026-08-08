#include "AirTaxiListModel.h"

#include <QSet>

#include <algorithm>
#include <cmath>

namespace {

constexpr std::size_t kMaximumTrackCount = 256;

bool isValidSurveillanceState(const atm::face::contracts::v1::SurveillanceState &state)
{
    if (state.schemaVersion != atm::face::contracts::v1::kSurveillanceSchemaVersion
        || state.tracks.size() > kMaximumTrackCount)
        return false;

    QSet<QString> callSigns;
    for (const auto &track : state.tracks) {
        const QString callSign = QString::fromStdString(track.callSign);
        const QString squawk = QString::fromStdString(track.squawk);
        if (callSign.isEmpty() || callSign.size() > 16 || callSigns.contains(callSign)
            || squawk.size() != 4
            || !std::all_of(squawk.cbegin(), squawk.cend(), [](QChar character) { return character.isDigit(); })
            || !std::isfinite(track.positionX) || track.positionX < 0.0 || track.positionX > 1.0
            || !std::isfinite(track.positionY) || track.positionY < 0.0 || track.positionY > 1.0
            || track.altitudeFt < 0 || track.altitudeFt > 10000
            || track.speedKts < 0 || track.speedKts > 250
            || track.heading < 0 || track.heading >= 360
            || track.trend < -1 || track.trend > 1)
            return false;
        callSigns.insert(callSign);
    }
    return true;
}

} // namespace

AirTaxiListModel::AirTaxiListModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_airTaxis{
            {"ATX101", "SAKET V1 - IGI V2", "1200 FT", "LEVEL", "4521", "EN ROUTE", 96, 0.64, 0.30, false, 284, "JOBY S4", 0, 78},
            {"SKY204", "NOIDA V3 - CP V4", "1800 FT", "DESC", "3164", "APPROACH", 82, 0.45, 0.40, false, 271, "ARCHER M", -320, 64},
            {"BLU307", "GURUGRAM V5 - IGI V2", "2200 FT", "LEVEL", "7702", "CONFLICT", 104, 0.37, 0.59, true, 36, "VOLOCITY", 0, 51},
            {"UAM412", "ROHINI V6 - AERO V7", "900 FT", "CLIMB", "5210", "DEPARTURE", 74, 0.57, 0.67, false, 318, "LILIUM JET", 280, 91},
            {"ECO518", "CP V4 - NOIDA V3", "2600 FT", "LEVEL", "6427", "EN ROUTE", 112, 0.76, 0.53, false, 112, "EVE AIR", 0, 73},
            {"ATX623", "IGI V2 - SAKET V1", "700 FT", "DESC", "2254", "APPROACH", 68, 0.24, 0.35, false, 61, "JOBY S4", -260, 42},
            {"SKY731", "AERO V7 - ROHINI V6", "1500 FT", "LEVEL", "1372", "EN ROUTE", 88, 0.52, 0.20, false, 297, "ARCHER M", 0, 69},
            {"MED805", "AIIMS V8 - IGI V2", "2400 FT", "CLIMB", "4615", "PRIORITY", 118, 0.70, 0.76, false, 84, "VOLOCITY", 340, 86},
      }
{
}

int AirTaxiListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_airTaxis.size();
}

QVariant AirTaxiListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_airTaxis.size())
        return {};

    const AirTaxi &airTaxi = m_airTaxis.at(index.row());
    switch (role) {
    case CallSignRole: return airTaxi.callSign;
    case RouteRole: return airTaxi.route;
    case LevelRole: return airTaxi.level;
    case TrendRole: return airTaxi.trend;
    case SquawkRole: return airTaxi.squawk;
    case StateRole: return airTaxi.state;
    case SpeedRole: return airTaxi.speed;
    case PositionXRole: return airTaxi.positionX;
    case PositionYRole: return airTaxi.positionY;
    case AlertRole: return airTaxi.alert;
    case HeadingRole: return airTaxi.heading;
    case VehicleTypeRole: return airTaxi.vehicleType;
    case VerticalRateRole: return airTaxi.verticalRate;
    case BatteryRole: return airTaxi.battery;
    case StatusLabelRole: return airTaxi.alert ? QStringLiteral("STCA") : airTaxi.state.left(3);
    case SeverityRole: return airTaxi.alert ? QStringLiteral("warning") : QStringLiteral("normal");
    default: return {};
    }
}

QHash<int, QByteArray> AirTaxiListModel::roleNames() const
{
    return {
        {CallSignRole, "callSign"},
        {RouteRole, "route"},
        {LevelRole, "level"},
        {TrendRole, "trend"},
        {SquawkRole, "squawk"},
        {StateRole, "state"},
        {SpeedRole, "speed"},
        {PositionXRole, "positionX"},
        {PositionYRole, "positionY"},
        {AlertRole, "alert"},
        {HeadingRole, "heading"},
        {VehicleTypeRole, "vehicleType"},
        {VerticalRateRole, "verticalRate"},
        {BatteryRole, "battery"},
        {StatusLabelRole, "statusLabel"},
        {SeverityRole, "severity"},
    };
}

QVariantMap AirTaxiListModel::airTaxiAt(int row) const
{
    if (row < 0 || row >= m_airTaxis.size())
        return {};

    const QModelIndex airTaxiIndex = index(row);
    QVariantMap airTaxi;
    const auto roles = roleNames();
    for (auto role = roles.cbegin(); role != roles.cend(); ++role)
        airTaxi.insert(QString::fromUtf8(role.value()), data(airTaxiIndex, role.key()));
    return airTaxi;
}

QVariantMap AirTaxiListModel::alertAirTaxi() const
{
    for (int row = 0; row < m_airTaxis.size(); ++row) {
        if (m_airTaxis.at(row).alert)
            return airTaxiAt(row);
    }
    return {};
}

int AirTaxiListModel::alertCount() const
{
    int count = 0;
    for (const AirTaxi &airTaxi : m_airTaxis) {
        if (airTaxi.alert)
            ++count;
    }
    return count;
}

bool AirTaxiListModel::updateFromState(const atm::face::contracts::v1::SurveillanceState &state)
{
    if (!isValidSurveillanceState(state))
        return false;

    beginResetModel();
    m_airTaxis.clear();
    m_airTaxis.reserve(static_cast<qsizetype>(state.tracks.size()));
    for (const auto &track : state.tracks) {
        m_airTaxis.append({QString::fromStdString(track.callSign),
                          QStringLiteral("UTM CORRIDOR"),
                          QStringLiteral("%1 FT").arg(track.altitudeFt),
                          track.trend > 0 ? QStringLiteral("CLIMB") : (track.trend < 0 ? QStringLiteral("DESC") : QStringLiteral("LEVEL")),
                          QString::fromStdString(track.squawk),
                          track.alert ? QStringLiteral("CONFLICT") : QStringLiteral("EN ROUTE"),
                          track.speedKts,
                          track.positionX,
                          track.positionY,
                          track.alert,
                          track.heading,
                          QString::fromStdString(track.vehicleType),
                          track.trend * 100,
                          75});
    }
    endResetModel();
    return true;
}