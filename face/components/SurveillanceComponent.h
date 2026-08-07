#pragma once

#include "face/interfaces/ISurveillance.h"

namespace atm::face::components {

class SurveillanceComponent final : public interfaces::ISurveillance
{
public:
    SurveillanceComponent();

    const contracts::v1::SurveillanceState &surveillanceState() const override;
    void advance() override;
    void reset() override;

private:
    contracts::v1::SurveillanceState m_state;
};

} // namespace atm::face::components