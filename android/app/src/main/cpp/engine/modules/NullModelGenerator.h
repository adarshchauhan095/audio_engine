#pragma once

#include "GeneratorParams.h"
#include "../utils/DeterministicRNG.h"

namespace phase5 {

class NullModelGenerator {
public:
    void init(double sampleRate) {
        sampleRate_ = sampleRate;
        rng_.setSeed(0x99AABBCC);
        prevNoise_ = 0.0f;
        dcBlockerX1_ = 0.0f;
        dcBlockerY1_ = 0.0f;
    }

    void reset() {
        prevNoise_ = 0.0f;
        dcBlockerX1_ = 0.0f;
        dcBlockerY1_ = 0.0f;
    }

    float process(const NullModelParams& params) {
        // Generate neutral white noise
        float rawNoise = rng_.nextFloatSymmetric() * params.noiseFloor;
        
        // Low-pass filter (1-pole) using "stability" parameter (0.0 to 1.0)
        // higher stability = more filtering (smoother noise)
        float alpha = 1.0f - params.stability;
        if (alpha < 0.01f) alpha = 0.01f;
        
        float filteredNoise = prevNoise_ + alpha * (rawNoise - prevNoise_);
        prevNoise_ = filteredNoise;
        
        // DC Blocker (1-pole HPF) to avoid DC drift
        // y[n] = x[n] - x[n-1] + R * y[n-1], R = 0.995
        const float R = 0.995f;
        float out = filteredNoise - dcBlockerX1_ + R * dcBlockerY1_;
        
        dcBlockerX1_ = filteredNoise;
        dcBlockerY1_ = out;

        return out * params.amplitude;
    }

private:
    double sampleRate_ = 48000.0;
    utils::DeterministicRNG rng_;
    float prevNoise_ = 0.0f;
    float dcBlockerX1_ = 0.0f;
    float dcBlockerY1_ = 0.0f;
};

} // namespace phase5
