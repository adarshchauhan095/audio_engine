#pragma once

#include "../Oscillator.h"

// Phase Interruption Patterning
class PIPModule {
public:
  void init(double sampleRate);
  void reset();
  float process(double baseFreq, float baseAmp, float pipInterval,
                float pipDuration);

private:
  Oscillator mainOsc_;
  double sampleRate_ = 48000.0;
  int samplesUntilToggle_ = 0;
  bool isSilent_ = false;
  /// Smoothed 0..1 gate (avoids clicks at pulse boundaries).
  float envelope_ = 0.0f;
  float pipEnvCoeff_ = 0.0f;
};
