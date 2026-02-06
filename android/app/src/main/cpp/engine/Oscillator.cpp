#include "Oscillator.h"
#include <cmath>

constexpr float kTwoPi = 6.28318530718f;
constexpr float kSampleRate = 48000.0f;

void Oscillator::setFrequency(float hz) {
  frequency_.store(hz, std::memory_order_relaxed);
}

float Oscillator::process() {
  float phaseInc = kTwoPi * frequency_.load(std::memory_order_relaxed) / kSampleRate;
  float value = std::sin(phase_);
  phase_ += phaseInc;
  if (phase_ >= kTwoPi) phase_ -= kTwoPi;
  return value;
}
