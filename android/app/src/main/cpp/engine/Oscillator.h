#pragma once

#include <atomic>

/// Frequency Control Module: sine oscillator with real-time frequency changes without clicks.
///
/// [setFrequency] is thread-safe (atomic target). Frequency is smoothed per-sample
/// so phase and phase increment evolve continuously—stable under large jumps and
/// prepared for a future tinnitus frequency detection module (same setFrequency API).
class Oscillator {
public:
  /// Sets the target frequency in Hz. Smoothed internally; safe to call from any thread.
  void setFrequency(float hz);

  /// Generates the next sample. Uses smoothed frequency for phase increment; phase wraps in [0, 2*PI).
  float process();

private:
  std::atomic<float> frequencyTarget_{440.0f};  ///< Thread-safe target frequency (Hz).
  float frequencyCurrent_ = 440.0f;            ///< Smoothed frequency used in process() (audio thread only).
  float phase_ = 0.0f;                          ///< Current phase in radians.
  float smoothingCoeff_ = 0.0f;                 ///< One-pole coefficient for frequency smoothing.
};
