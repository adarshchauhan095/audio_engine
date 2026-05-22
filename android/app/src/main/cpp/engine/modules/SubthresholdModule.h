#pragma once

#include "../Oscillator.h"

// Applies AM and FM modulation
class SubthresholdModule {
public:
    void init(double sampleRate);
    void resetPhases();
    float process(double baseFreq, float baseAmp);

private:
    Oscillator mainOsc_;
    Oscillator amOsc_;
    Oscillator fmOsc_;
};
