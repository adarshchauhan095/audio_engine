#include "Oscillator.h"

#include <cmath>

namespace {
constexpr double kTwoPi = 6.28318530717958647692;
constexpr double kSampleRate = 48000.0;
// Frequency smoothing to avoid clicks during step changes (e.g. AMS higher/lower).
// Kept short to stay responsive while preventing discontinuities at high Hz.
constexpr double kFrequencySmoothingMs = 20.0;

double smoothingCoeffForMs(double timeMs, double sampleRate) {
  if (timeMs <= 0.0 || sampleRate <= 0.0) return 0.0;
  const double smoothingSamples = (timeMs * 0.001) * sampleRate;
  return std::exp(-1.0 / smoothingSamples);
}

double sanitizeFrequency(double hz) {
  if (!std::isfinite(hz)) return 0.0;
  return hz;
}
}  // namespace

void Oscillator::setFrequency(float hz) {
  setTargetFrequency(static_cast<double>(hz));
}

void Oscillator::setTargetFrequency(double hz) {
  if (smoothingCoeff_ == 0.0) {
    smoothingCoeff_ = smoothingCoeffForMs(kFrequencySmoothingMs, kSampleRate);
  }
  frequencyTarget_.store(sanitizeFrequency(hz), std::memory_order_relaxed);
}

void Oscillator::resetPhase() {
  phase_ = 0.0;
}

float Oscillator::process() {
  if (smoothingCoeff_ == 0.0) {
    smoothingCoeff_ = smoothingCoeffForMs(kFrequencySmoothingMs, kSampleRate);
  }

  const double target = frequencyTarget_.load(std::memory_order_relaxed);
  frequencyCurrent_ = target + smoothingCoeff_ * (frequencyCurrent_ - target);
  const double phaseInc = kTwoPi * frequencyCurrent_ / kSampleRate;

  const float value = static_cast<float>(std::sin(phase_));
  phase_ += phaseInc;
  if (phase_ >= kTwoPi || phase_ <= -kTwoPi) {
    phase_ = std::fmod(phase_, kTwoPi);
  }
  if (phase_ < 0.0) {
    phase_ += kTwoPi;
  }
  return value;
}

