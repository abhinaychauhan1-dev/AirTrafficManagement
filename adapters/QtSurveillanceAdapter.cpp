#include "QtSurveillanceAdapter.h"

QtSurveillanceAdapter::QtSurveillanceAdapter(atm::face::interfaces::ISurveillance &surveillance,
                                             AirTaxiListModel &airTaxiListModel,
                                             AirTrafficViewModel &airTrafficViewModel,
                                             QObject *parent)
    : QObject(parent)
    , m_surveillance(surveillance)
    , m_airTaxiListModel(airTaxiListModel)
    , m_airTrafficViewModel(airTrafficViewModel)
{
    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &QtSurveillanceAdapter::onTick);
    m_timer.start();
}

void QtSurveillanceAdapter::onTick()
{
    m_surveillance.advance();
    const auto &state = m_surveillance.surveillanceState();
    if (!m_airTaxiListModel.updateFromState(state)) {
        m_airTrafficViewModel.onSurveillanceInputRejected();
        return;
    }
    m_airTrafficViewModel.onSurveillanceUpdate();
}