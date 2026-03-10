#include "RMPModule.h"

RMPModule::RMPModule() : rng_(std::random_device{}()) {}

void RMPModule::init(double sampleRate) {
    sampleRate_ = sampleRate;
}

float RMPModule::process(double baseFreq, float baseAmp) {
    if (samplesUntilNextJitter_ <= 0) {
        std::uniform_int_distribution<int> timeDist(
            (int)(sampleRate_ * 0.1), (int)(sampleRate_ * 0.3));
        samplesUntilNextJitter_ = timeDist(rng_);
        
        std::uniform_real_distribution<double> freqDist(-5.0, 5.0);
        freqJitter_ = freqDist(rng_);
        
        std::uniform_real_distribution<float> ampDist(-0.1f, 0.1f);
        ampJitter_ = ampDist(rng_);
    }
    samplesUntilNextJitter_--;
    
    mainOsc_.setTargetFrequency(baseFreq + freqJitter_);
    float currentAmp = baseAmp + (baseAmp * ampJitter_);
    if (currentAmp < 0.0f) currentAmp = 0.0f;
    if (currentAmp > 1.0f) currentAmp = 1.0f;
    
    return mainOsc_.process() * currentAmp;
}
