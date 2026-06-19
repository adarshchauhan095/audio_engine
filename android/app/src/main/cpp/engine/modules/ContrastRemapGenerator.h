#pragma once

#include "GeneratorParams.h"
#include <cmath>

namespace phase5 {

class ContrastRemapGenerator {
public:
    void init(double sampleRate) {
        sampleRate_ = sampleRate;
        carrierPhase_ = 0.0;
        modulatorPhase_ = 0.0;
    }

    void reset() {
        carrierPhase_ = 0.0;
        modulatorPhase_ = 0.0;
    }

    float process(const ContrastRemapParams& params) {
        // Modulator controls the "contrast" movement
        const double modPhaseInc = kTwoPi * params.modulationSpeed / sampleRate_;
        float modSignal = static_cast<float>(std::sin(modulatorPhase_));
        
        modulatorPhase_ += modPhaseInc;
        if (modulatorPhase_ >= kTwoPi) modulatorPhase_ -= kTwoPi;

        // Sideband-like frequency shaping via FM
        float currentFreq = params.baseFrequency + (modSignal * params.contrastShift);
        const double carrierPhaseInc = kTwoPi * currentFreq / sampleRate_;
        
        float carrierSignal = static_cast<float>(std::sin(carrierPhase_));
        
        carrierPhase_ += carrierPhaseInc;
        if (carrierPhase_ >= kTwoPi) carrierPhase_ -= kTwoPi;
        
        // Contrast width applied as a dynamic waveshaper (soft clipping)
        float shaped = carrierSignal * (1.0f + params.contrastWidth * std::abs(modSignal));
        // Keep it somewhat bounded before final clamp
        shaped = std::tanh(shaped);

        return shaped * params.amplitude;
    }

private:
    double sampleRate_ = 48000.0;
    double carrierPhase_ = 0.0;
    double modulatorPhase_ = 0.0;
    static constexpr double kTwoPi = 6.28318530717958647692;
};

} // namespace phase5
