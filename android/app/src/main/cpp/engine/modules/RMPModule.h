#pragma once

#include <random>
#include "../Oscillator.h"

// Random Micro Perturbation
class RMPModule {
public:
    RMPModule();
    void init(double sampleRate);
    float process(double baseFreq, float baseAmp);

private:
    Oscillator mainOsc_;
    std::mt19937 rng_;
    double sampleRate_ = 48000.0;
    int samplesUntilNextJitter_ = 0;
    double freqJitter_ = 0.0;
    float ampJitter_ = 0.0f;
};
