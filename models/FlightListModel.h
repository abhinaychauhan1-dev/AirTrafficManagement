#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QString>

class FlightListModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        CallSignRole = Qt::UserRole + 1,
        RouteRole,
        LevelRole,
        TrendRole,
        SquawkRole,
        StateRole,
        SpeedRole,
        PositionXRole,
        PositionYRole,
        AlertRole,
        HeadingRole,
        AircraftTypeRole
    };
    Q_ENUM(Role)

    explicit FlightListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariantMap flightAt(int row) const;
    int alertCount() const;

private:
    struct Flight {
        QString callSign;
        QString route;
        QString level;
        QString trend;
        QString squawk;
        QString state;
        int speed;
        qreal positionX;
        qreal positionY;
        bool alert;
        int heading;
        QString aircraftType;
    };

    QList<Flight> m_flights;
};