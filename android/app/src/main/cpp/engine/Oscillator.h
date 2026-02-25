#pragma once

#include <atomic>

/// Sine oscillator with smooth real-time frequency changes.
///
/// [setFrequency] remains backward-compatible and delegates to a
/// high-precision target setter.
class Oscillator {
public:
  /// Sets the target frequency in Hz.
  void setFrequency(float hz);

  /// Sets the target frequency in Hz with double precision.
  void setTargetFrequency(double hz);

  /// Generates the next audio sample.
  float process();

private:
  std::atomic<double> frequencyTarget_{440.0};
  double frequencyCurrent_ = 440.0;
  double phase_ = 0.0;
  double smoothingCoeff_ = 0.0;
};

