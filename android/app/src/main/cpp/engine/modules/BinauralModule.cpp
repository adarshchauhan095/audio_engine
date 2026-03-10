#include "BinauralModule.h"

void BinauralModule::init(double sampleRate) {
}

StereoSample BinauralModule::process(double baseFreq, float baseAmp) {
    leftOsc_.setTargetFrequency(baseFreq);
    rightOsc_.setTargetFrequency(baseFreq + 5.0); // 5 Hz binaural beat
    
    StereoSample out;
    out.left = leftOsc_.process() * baseAmp;
    out.right = rightOsc_.process() * baseAmp;
    return out;
}
