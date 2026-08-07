#include "FlightListModel.h"

#include <QtMath>

FlightListModel::FlightListModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_flights{
          {"AIC402", "VIDP - VABB", "F350", "-", "4251", "CRUISE", 458, 0.64, 0.30, false, 284, "B77W/H", 0},
          {"UAE215", "OMDB - VIDP", "F390", "-", "3164", "INBOUND", 472, 0.45, 0.40, false, 271, "A388/H", 0},
          {"IGO613", "VABB - VIDP", "F280", "-", "7702", "CONFLICT", 421, 0.37, 0.59, true, 36, "A320/M", 0},
          {"VTI829", "VILK - VIDP", "F310", "-", "5210", "INBOUND", 438, 0.57, 0.67, false, 318, "A321/M", 0},
          {"BAW143", "EGLL - VIDP", "F370", "-", "6427", "CRUISE", 465, 0.76, 0.53, false, 112, "B789/H", 0},
          {"AXB118", "VIJP - VIDP", "F240", "-", "2254", "DESCENT", 396, 0.24, 0.35, false, 61, "B738/M", -1200},
          {"SIA406", "WSSS - EGLL", "F410", "-", "1372", "OVERFLIGHT", 481, 0.52, 0.20, false, 297, "A359/H", 0},
          {"QTR578", "OTHH - VTBS", "F330", "-", "4615", "OVERFLIGHT", 449, 0.70, 0.76, false, 84, "B77W/H", 0},
      }
{
}

int FlightListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_flights.size();
}

QVariant FlightListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_flights.size())
        return {};

    const Flight &flight = m_flights.at(index.row());
    switch (role) {
    case CallSignRole: return flight.callSign;
    case RouteRole: return flight.route;
    case LevelRole: return flight.level;
    case TrendRole: return flight.trend;
    case SquawkRole: return flight.squawk;
    case StateRole: return flight.state;
    case SpeedRole: return flight.speed;
    case PositionXRole: return flight.positionX;
    case PositionYRole: return flight.positionY;
    case AlertRole: return flight.alert;
    case HeadingRole: return flight.heading;
    case AircraftTypeRole: return flight.aircraftType;
    case VerticalRateRole: return flight.verticalRate;
    case StatusLabelRole: return flight.alert ? QStringLiteral("STCA") : flight.state.left(3);
    case SeverityRole: return flight.alert ? QStringLiteral("warning") : QStringLiteral("normal");
    default: return {};
    }
}

QHash<int, QByteArray> FlightListModel::roleNames() const
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
        {AircraftTypeRole, "aircraftType"},
        {VerticalRateRole, "verticalRate"},
        {StatusLabelRole, "statusLabel"},
        {SeverityRole, "severity"},
    };
}

QVariantMap FlightListModel::flightAt(int row) const
{
    if (row < 0 || row >= m_flights.size())
        return {};

    const QModelIndex flightIndex = index(row);
    QVariantMap flight;
    const auto roles = roleNames();
    for (auto role = roles.cbegin(); role != roles.cend(); ++role)
        flight.insert(QString::fromUtf8(role.value()), data(flightIndex, role.key()));
    return flight;
}

QVariantMap FlightListModel::alertFlight() const
{
    for (int row = 0; row < m_flights.size(); ++row) {
        if (m_flights.at(row).alert)
            return flightAt(row);
    }
    return {};
}

int FlightListModel::alertCount() const
{
    int count = 0;
    for (const Flight &flight : m_flights) {
        if (flight.alert)
            ++count;
    }
    return count;
}

bool FlightListModel::advanceOneSecond(int tick)
{
    const int previousAlertCount = alertCount();

    for (int row = 0; row < m_flights.size(); ++row) {
        Flight &flight = m_flights[row];
        const qreal headingRadians = qDegreesToRadians(static_cast<qreal>(flight.heading));
        const qreal distance = flight.speed * 0.0000022;
        flight.positionX += qSin(headingRadians) * distance;
        flight.positionY -= qCos(headingRadians) * distance;

        if (flight.positionX < .06)
            flight.positionX = .94;
        else if (flight.positionX > .94)
            flight.positionX = .06;
        if (flight.positionY < .08)
            flight.positionY = .92;
        else if (flight.positionY > .92)
            flight.positionY = .08;

        if ((tick + row) % 8 == 0)
            flight.heading = (flight.heading + (row % 2 == 0 ? 1 : 359)) % 360;
        if ((tick + row) % 6 == 0)
            flight.speed = qBound(320, flight.speed + (row % 2 == 0 ? 1 : -1), 510);
    }

    Flight &conflictFlight = m_flights[2];
    conflictFlight.alert = tick % 30 < 15;
    conflictFlight.state = conflictFlight.alert ? QStringLiteral("CONFLICT") : QStringLiteral("INBOUND");

    emit dataChanged(index(0), index(m_flights.size() - 1),
                     {SpeedRole, PositionXRole, PositionYRole, AlertRole, HeadingRole,
                      StateRole, StatusLabelRole, SeverityRole});
    return previousAlertCount != alertCount();
}