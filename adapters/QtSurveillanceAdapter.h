#pragma once

#include "face/interfaces/ISurveillance.h"
#include "models/AirTaxiListModel.h"
#include "viewmodels/AirTrafficViewModel.h"

#include <QObject>
#include <QTimer>

class QtSurveillanceAdapter final : public QObject
{
    Q_OBJECT
public:
    explicit QtSurveillanceAdapter(atm::face::interfaces::ISurveillance &surveillance,
                                   AirTaxiListModel &airTaxiListModel,
                                   AirTrafficViewModel &airTrafficViewModel,
                                   QObject *parent = nullptr);

private slots:
    void onTick();

private:
    atm::face::interfaces::ISurveillance &m_surveillance;
    AirTaxiListModel &m_airTaxiListModel;
    AirTrafficViewModel &m_airTrafficViewModel;
    QTimer m_timer;
};