#pragma once

#include "GeneratorParams.h"
#include "../utils/DeterministicRNG.h"
#include <cmath>

namespace phase5 {

class SalienceScramblerGenerator {
public:
    void init(double sampleRate) {
        sampleRate_ = sampleRate;
        rng_.setSeed(0x55667788);
        resetState();
    }

    void reset() {
        resetState();
    }

    float process(const SalienceScramblerParams& params) {
        float out = 0.0f;

        if (burstActive_) {
            // Generate impulse cluster (noise-like)
            out = rng_.nextFloatSymmetric();
            
            // Envelope (fade in/out to avoid clicks)
            float env = 1.0f;
            int samplesRemaining = burstSamples_ - samplesInCurrentBurst_;
            if (samplesInCurrentBurst_ < kFadeSamples) {
                env = static_cast<float>(samplesInCurrentBurst_) / kFadeSamples;
            } else if (samplesRemaining < kFadeSamples) {
                env = static_cast<float>(samplesRemaining) / kFadeSamples;
            }
            out *= env;

            samplesInCurrentBurst_++;
            if (samplesInCurrentBurst_ >= burstSamples_) {
                burstActive_ = false;
                scheduleNextBurst(params);
            }
        } else {
            samplesUntilNextBurst_--;
            if (samplesUntilNextBurst_ <= 0) {
                startBurst(params);
            }
        }

        return out * params.amplitude;
    }

private:
    double sampleRate_ = 48000.0;
    utils::DeterministicRNG rng_;
    
    bool burstActive_ = false;
    int samplesInCurrentBurst_ = 0;
    int burstSamples_ = 0;
    int samplesUntilNextBurst_ = 0;
    
    // 1ms fade
    int kFadeSamples = 48; 

    void resetState() {
        burstActive_ = false;
        samplesInCurrentBurst_ = 0;
        burstSamples_ = 0;
        samplesUntilNextBurst_ = static_cast<int>(sampleRate_); // start after 1 sec
        kFadeSamples = static_cast<int>(sampleRate_ * 0.001); // 1ms
    }

    void scheduleNextBurst(const SalienceScramblerParams& params) {
        if (params.burstRate <= 0.0f) {
            samplesUntilNextBurst_ = static_cast<int>(sampleRate_);
            return;
        }
        
        float baseIntervalSec = 1.0f / params.burstRate;
        float jitterSec = rng_.nextFloatSymmetric() * params.jitterAmount;
        float nextInterval = baseIntervalSec + jitterSec;
        if (nextInterval < 0.01f) nextInterval = 0.01f;
        
        samplesUntilNextBurst_ = static_cast<int>(nextInterval * sampleRate_);
    }

    void startBurst(const SalienceScramblerParams& params) {
        burstActive_ = true;
        samplesInCurrentBurst_ = 0;
        burstSamples_ = static_cast<int>((params.burstLengthMs / 1000.0f) * sampleRate_);
        // Ensure burst is at least 2x fade length
        if (burstSamples_ < kFadeSamples * 2) {
            burstSamples_ = kFadeSamples * 2;
        }
    }
};

} // namespace phase5
