#pragma once

#include "face/contracts/v1/Surveillance.h"

namespace atm::face::interfaces {

class ISurveillance
{
public:
    virtual ~ISurveillance() = default;
    virtual const contracts::v1::SurveillanceState &surveillanceState() const = 0;
    virtual void advance() = 0;
    virtual void reset() = 0;
};

} // namespace atm::face::interfaces