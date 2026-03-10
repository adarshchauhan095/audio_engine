#pragma once

#include "../Oscillator.h"

// Phase Interruption Patterning
class PIPModule {
public:
    void init(double sampleRate);
    float process(double baseFreq, float baseAmp);

private:
    Oscillator mainOsc_;
    double sampleRate_ = 48000.0;
    int samplesUntilToggle_ = 0;
    bool isSilent_ = false;
};
