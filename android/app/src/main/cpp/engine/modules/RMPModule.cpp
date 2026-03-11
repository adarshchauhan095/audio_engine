#include "RMPModule.h"

RMPModule::RMPModule() : rng_(std::random_device{}()) {}

void RMPModule::init(double sampleRate) { sampleRate_ = sampleRate; }

float RMPModule::process(double baseFreq, float baseAmp, float rmpDepth,
                         float rmpRate) {
  if (samplesUntilNextJitter_ <= 0) {
    // rmpRate determines how often we jitter. 1Hz = mostly steady, 10Hz = fast
    // flutter. We'll calculate a window around the rate to give it a human
    // "random" feel.
    double targetSeconds = 1.0 / (double)rmpRate;
    std::uniform_int_distribution<int> timeDist(
        (int)(sampleRate_ * (targetSeconds * 0.8)),
        (int)(sampleRate_ * (targetSeconds * 1.2)));
    samplesUntilNextJitter_ = timeDist(rng_);

    // rmpDepth controls the frequency and amplitude spread
    // If depth is 0.1 (10%), freq shakes by +/- 10Hz, amp shakes by +/- 10%
    float freqSpread = rmpDepth * 100.0f;
    std::uniform_real_distribution<double> freqDist(-freqSpread, freqSpread);
    freqJitter_ = freqDist(rng_);

    std::uniform_real_distribution<float> ampDist(-rmpDepth, rmpDepth);
    ampJitter_ = ampDist(rng_);
  }
  samplesUntilNextJitter_--;

  mainOsc_.setTargetFrequency(baseFreq + freqJitter_);
  float currentAmp = baseAmp + (baseAmp * ampJitter_);
  if (currentAmp < 0.0f)
    currentAmp = 0.0f;
  if (currentAmp > 1.0f)
    currentAmp = 1.0f;

  return mainOsc_.process() * currentAmp;
}
