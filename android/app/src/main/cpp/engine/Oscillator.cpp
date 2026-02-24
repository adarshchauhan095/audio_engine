#include "Oscillator.h"
#include <cmath>

constexpr float kTwoPi = 6.28318530718f;
constexpr float kSampleRate = 48000.0f;
/// Frequency smoothing time (ms) for click-free real-time changes.
constexpr float kFrequencySmoothingMs = 3.0f;

namespace {
float smoothingCoeffForMs(float timeMs, float sampleRate) {
  if (timeMs <= 0.0f || sampleRate <= 0.0f) return 0.0f;
  const float smoothingSamples = (timeMs * 0.001f) * sampleRate;
  return std::exp(-1.0f / smoothingSamples);
}
}  // namespace

void Oscillator::setFrequency(float hz) {
  if (smoothingCoeff_ == 0.0f) {
    smoothingCoeff_ = smoothingCoeffForMs(kFrequencySmoothingMs, kSampleRate);
  }
  frequencyTarget_.store(hz, std::memory_order_relaxed);
}

float Oscillator::process() {
  if (smoothingCoeff_ == 0.0f) {
    smoothingCoeff_ = smoothingCoeffForMs(kFrequencySmoothingMs, kSampleRate);
  }
  const float target = frequencyTarget_.load(std::memory_order_relaxed);
  frequencyCurrent_ = target + smoothingCoeff_ * (frequencyCurrent_ - target);
  const float phaseInc = kTwoPi * frequencyCurrent_ / kSampleRate;

  const float value = std::sin(phase_);
  phase_ += phaseInc;
  if (phase_ >= kTwoPi) {
    phase_ -= kTwoPi;
  }
  return value;
}
