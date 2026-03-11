#pragma once

#include "../Oscillator.h"
#include <random>

// Random Micro Perturbation
class RMPModule {
public:
  RMPModule();
  void init(double sampleRate);
  float process(double baseFreq, float baseAmp, float rmpDepth, float rmpRate);

private:
  Oscillator mainOsc_;
  std::mt19937 rng_;
  double sampleRate_ = 48000.0;
  int samplesUntilNextJitter_ = 0;
  double freqJitter_ = 0.0;
  float ampJitter_ = 0.0f;
};
