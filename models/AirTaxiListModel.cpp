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