#include "RMPModule.h"

#include <cmath>

namespace {
constexpr float kRmpAmpSmoothMs = 5.0f;

float smoothingCoeffFromMs(float timeMs, double sampleRate) {
  if (timeMs <= 0.0f || sampleRate <= 0.0) {
    return 0.0f;
  }
  const float smoothingSamples =
      (timeMs * 0.001f) * static_cast<float>(sampleRate);
  return std::exp(-1.0f / smoothingSamples);
}
} // namespace

RMPModule::RMPModule() : rng_(std::random_device{}()) {}

void RMPModule::init(double sampleRate) {
  sampleRate_ = sampleRate;
  ampSmoothCoeff_ = smoothingCoeffFromMs(kRmpAmpSmoothMs, sampleRate_);
}

void RMPModule::reset() {
  samplesUntilNextJitter_ = 0;
  freqJitter_ = 0.0;
  ampJitter_ = 0.0f;
  smoothedAmp_ = -1.0f;
}

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
  float targetAmp = baseAmp + (baseAmp * ampJitter_);
  if (targetAmp < 0.0f)
    targetAmp = 0.0f;
  if (targetAmp > 1.0f)
    targetAmp = 1.0f;

  if (smoothedAmp_ < 0.0f) {
    smoothedAmp_ = targetAmp;
  } else {
    smoothedAmp_ =
        targetAmp + ampSmoothCoeff_ * (smoothedAmp_ - targetAmp);
  }

  return mainOsc_.process() * smoothedAmp_;
}
