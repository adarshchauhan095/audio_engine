#pragma once

#include "../Oscillator.h"

struct StereoSample {
    float left = 0.0f;
    float right = 0.0f;
};

class BinauralModule {
public:
    void init(double sampleRate);
    StereoSample process(double baseFreq, float baseAmp);

private:
    Oscillator leftOsc_;
    Oscillator rightOsc_;
};
