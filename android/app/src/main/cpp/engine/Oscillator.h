#pragma once // Ensures this header file is included only once during compilation.

#include <atomic> // For std::atomic to ensure thread-safe access to frequency.

/// @class Oscillator
/// @brief Generates a sine wave signal.
///
/// This class is responsible for producing an audio waveform (specifically a sine wave)
/// at a given frequency. It maintains the current phase of the oscillation
/// and provides a method to generate the next sample in the sequence.
class Oscillator {
public:
  /// @brief Sets the frequency of the oscillator.
  ///
  /// Uses an atomic operation to ensure thread-safe updates to the frequency.
  /// @param hz The desired frequency in Hertz.
  void setFrequency(float hz);

  /// @brief Generates and returns the next audio sample from the oscillator.
  ///
  /// This method advances the phase of the sine wave and returns the corresponding
  /// amplitude value.
  /// @return The next floating-point audio sample.
  float process();

private:
  std::atomic<float> frequency_{440.0f}; ///< Atomic float for thread-safe frequency control, initialized to 440 Hz.
  float phase_ = 0.0f;                   ///< Current phase of the oscillator in radians, ranges from 0 to 2*PI.
};
