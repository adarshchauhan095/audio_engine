#pragma once

#include "PhaseBreakerOp.h"
#include "AntiCorrelationOp.h"
#include "ContrastRemapOp.h"
#include "SalienceScramblerOp.h"
#include "NullModelOp.h"
#include "../TherapyConfig.h"

namespace phase5 {

// Central registry for Phase 5.2 Expansion Layer generators.
// Future ANAPS full integration will control this programmatically.
class OperatorRegistry {
public:
    void init(double sampleRate);
    void reset();

    // Returns a mono mix of all active generators
    float process(const TherapyConfig& config);

private:
    PhaseBreakerOp phaseBreaker_;
    AntiCorrelationOp antiCorrelation_;
    ContrastRemapOp contrastRemap_;
    SalienceScramblerOp salienceScrambler_;
    NullModelOp nullModel_;
};

} // namespace phase5
