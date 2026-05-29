#pragma once

#include "../Oscillator.h"
#include <random>

// Random Micro Perturbation
class RMPModule {
public:
  RMPModule();
  void init(double sampleRate);
  void reset();
  float process(double baseFreq, float baseAmp, float rmpDepth, float rmpRate);

private:
  Oscillator mainOsc_;
  std::mt19937 rng_;
  double sampleRate_ = 48000.0;
  int samplesUntilNextJitter_ = 0;
  double freqJitter_ = 0.0;
  float ampJitter_ = 0.0f;
  /// One-pole smoothing toward target amplitude (avoids clicks on jitter steps).
  float smoothedAmp_ = 0.0f;
  float ampSmoothCoeff_ = 0.0f;
};
