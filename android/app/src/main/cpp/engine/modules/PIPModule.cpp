#include "PIPModule.h"

void PIPModule::init(double sampleRate) {
    sampleRate_ = sampleRate;
}

float PIPModule::process(double baseFreq, float baseAmp) {
    if (samplesUntilToggle_ <= 0) {
        if (isSilent_) {
            samplesUntilToggle_ = (int)(sampleRate_ * 0.2); // 200ms tone
        } else {
            samplesUntilToggle_ = (int)(sampleRate_ * 0.02); // 20ms silence
        }
        isSilent_ = !isSilent_;
    }
    samplesUntilToggle_--;
    
    mainOsc_.setTargetFrequency(baseFreq);
    float sample = mainOsc_.process();
    return isSilent_ ? 0.0f : (sample * baseAmp);
}
