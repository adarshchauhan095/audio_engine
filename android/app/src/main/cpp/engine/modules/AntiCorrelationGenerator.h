#pragma once

#include "GeneratorParams.h"
#include <cmath>
#include <array>

namespace phase5 {

class AntiCorrelationGenerator {
public:
    void init(double sampleRate) {
        sampleRate_ = sampleRate;
        phase_ = 0.0;
        writeIndex_ = 0;
        delayBuffer_.fill(0.0f);
    }

    void reset() {
        phase_ = 0.0;
        writeIndex_ = 0;
        delayBuffer_.fill(0.0f);
    }

    float process(const AntiCorrelationParams& params) {
        const double phaseInc = kTwoPi * params.baseFrequency / sampleRate_;
        
        float currentSample = static_cast<float>(std::sin(phase_));
        
        phase_ += phaseInc;
        if (phase_ >= kTwoPi) phase_ -= kTwoPi;
        if (phase_ < 0.0) phase_ += kTwoPi;

        // Calculate delay in samples
        float delaySamples = (params.delayMs / 1000.0f) * static_cast<float>(sampleRate_);
        int delayInt = static_cast<int>(delaySamples);
        if (delayInt < 0) delayInt = 0;
        if (delayInt >= kMaxDelaySamples) delayInt = kMaxDelaySamples - 1;

        int readIndex = writeIndex_ - delayInt;
        if (readIndex < 0) readIndex += kMaxDelaySamples;

        float delayedSample = delayBuffer_[readIndex];

        // Store current sample
        delayBuffer_[writeIndex_] = currentSample;
        writeIndex_ = (writeIndex_ + 1) % kMaxDelaySamples;

        // Anti-correlation: invert delayed signal and mix
        float out = currentSample - (delayedSample * params.inversionDepth);

        return out * params.amplitude;
    }

private:
    double sampleRate_ = 48000.0;
    double phase_ = 0.0;
    static constexpr double kTwoPi = 6.28318530717958647692;
    
    // Max 40ms delay at 48kHz = 1920 samples. 2048 is safe power of 2.
    static constexpr int kMaxDelaySamples = 2048;
    std::array<float, kMaxDelaySamples> delayBuffer_{};
    int writeIndex_ = 0;
};

} // namespace phase5
