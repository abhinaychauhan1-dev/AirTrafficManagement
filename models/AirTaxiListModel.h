#pragma once

#include "face/contracts/v1/Surveillance.h"

#include <QAbstractListModel>
#include <QList>
#include <QString>

class AirTaxiListModel final : public QAbstractListModel
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
        VehicleTypeRole,
        VerticalRateRole,
        BatteryRole,
        StatusLabelRole,
        SeverityRole
    };
    Q_ENUM(Role)

    explicit AirTaxiListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariantMap airTaxiAt(int row) const;
    QVariantMap alertAirTaxi() const;
    int alertCount() const;
    bool advanceOneSecond(int tick);
    void updateFromState(const atm::face::contracts::v1::SurveillanceState &state);

private:
    struct AirTaxi {
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
        QString vehicleType;
        int verticalRate;
        int battery;
    };

    QList<AirTaxi> m_airTaxis;
};