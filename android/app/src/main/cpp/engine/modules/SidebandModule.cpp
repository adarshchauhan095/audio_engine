#include "SidebandModule.h"

void SidebandModule::init(double sampleRate) {
}

float SidebandModule::process(double baseFreq, float baseAmp) {
    lowerSideband_.setTargetFrequency(baseFreq - 100.0);
    upperSideband_.setTargetFrequency(baseFreq + 100.0);
    mainOsc_.setTargetFrequency(baseFreq);
    
    float s1 = lowerSideband_.process();
    float s2 = upperSideband_.process();
    float m = mainOsc_.process();
    
    return (s1 + s2 + m) * 0.333f * baseAmp;
}
