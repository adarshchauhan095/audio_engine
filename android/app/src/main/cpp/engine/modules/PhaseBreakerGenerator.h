#pragma once

#include "GeneratorParams.h"
#include "../utils/DeterministicRNG.h"
#include <cmath>

namespace phase5 {

class PhaseBreakerGenerator {
public:
    void init(double sampleRate) {
        sampleRate_ = sampleRate;
        phase_ = 0.0;
        rng_.setSeed(0x11223344);
    }

    void reset() {
        phase_ = 0.0;
    }

    float process(const PhaseBreakerParams& params) {
        // Drift frequency slightly
        float drift = rng_.nextFloatSymmetric() * params.driftAmount * params.driftSpeed;
        float currentFreq = params.baseFrequency + drift;
        
        // Jitter phase
        float jitter = rng_.nextFloatSymmetric() * params.phaseJitter;

        const double phaseInc = kTwoPi * currentFreq / sampleRate_;
        
        float value = static_cast<float>(std::sin(phase_ + jitter)) * params.amplitude;
        
        phase_ += phaseInc;
        if (phase_ >= kTwoPi) phase_ -= kTwoPi;
        if (phase_ < 0.0) phase_ += kTwoPi;

        return value;
    }

private:
    double sampleRate_ = 48000.0;
    double phase_ = 0.0;
    utils::DeterministicRNG rng_;
    static constexpr double kTwoPi = 6.28318530717958647692;
};

} // namespace phase5
