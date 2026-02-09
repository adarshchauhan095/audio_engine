#include "Oscillator.h" // Includes the declaration of the Oscillator class.
#include <cmath>          // For std::sin function.

/// @brief Constant for 2 * PI, used in phase calculations for trigonometric functions.
constexpr float kTwoPi = 6.28318530718f;

/// @brief The sample rate of the audio system in Hertz.
/// All audio processing is performed at this sample rate.
constexpr float kSampleRate = 48000.0f;

/// @brief Sets the frequency of the oscillator.
///
/// Uses an atomic store operation to ensure thread-safe updates to the frequency.
/// `std::memory_order_relaxed` is used as the order of operations between threads
/// does not need to be strictly synchronized beyond atomicity for this variable.
///
/// @param hz The desired frequency in Hertz.
void Oscillator::setFrequency(float hz) {
  frequency_.store(hz, std::memory_order_relaxed);
}

/// @brief Generates and returns the next audio sample from the oscillator.
///
/// This method calculates the phase increment based on the current frequency
/// and sample rate, generates a sine wave sample, updates the phase, and
/// ensures the phase remains within the 0 to 2*PI range.
///
/// @return The next floating-point audio sample of the sine wave.
float Oscillator::process() {
  // Calculate the phase increment for the current frequency.
  // This determines how much the phase advances for each sample.
  float phaseInc = kTwoPi * frequency_.load(std::memory_order_relaxed) / kSampleRate;

  // Generate a sine wave value based on the current phase.
  float value = std::sin(phase_);

  // Advance the phase for the next sample.
  phase_ += phaseInc;

  // Wrap the phase around if it exceeds 2*PI to keep it within a single cycle.
  if (phase_ >= kTwoPi) {
    phase_ -= kTwoPi;
  }
  return value; // Return the generated sample.
}
