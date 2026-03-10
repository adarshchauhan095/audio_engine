#pragma once

#include "../Oscillator.h"

class SidebandModule {
public:
    void init(double sampleRate);
    float process(double baseFreq, float baseAmp);

private:
    Oscillator lowerSideband_;
    Oscillator upperSideband_;
    Oscillator mainOsc_;
};
