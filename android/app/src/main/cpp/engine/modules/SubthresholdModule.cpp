#include "SubthresholdModule.h"

void SubthresholdModule::init(double sampleRate) {
    amOsc_.setTargetFrequency(1.0); // 1 Hz AM
    fmOsc_.setTargetFrequency(3.0); // 3 Hz FM
}

float SubthresholdModule::process(double baseFreq, float baseAmp) {
    float amVal = amOsc_.process();
    float fmVal = fmOsc_.process();
    
    double currentFreq = baseFreq + (fmVal * 3.0);
    mainOsc_.setTargetFrequency(currentFreq);
    
    float currentAmp = baseAmp * (0.75f + (amVal * 0.25f));
    return mainOsc_.process() * currentAmp;
}
