#include "ParameterSmoother.h"

#include <cmath>

// Sample-accurate ramp: process() advances one sample toward target.
// No glitches when UI sends rapid changes; setTarget() is thread-safe.

void ParameterSmoother::setSmoothingTimeMs(float timeMs, float sampleRate) {
  if (timeMs <= 0.0f || sampleRate <= 0.0f) {
    coefficient_ = 0.0f;
    return;
  }

  const float smoothingSamples = (timeMs * 0.001f) * sampleRate;
  coefficient_ = std::exp(-1.0f / smoothingSamples);
}

void ParameterSmoother::reset(float value) {
  current_.store(value, std::memory_order_relaxed);
  target_.store(value, std::memory_order_relaxed);
}

void ParameterSmoother::setTarget(float value) {
  target_.store(value, std::memory_order_relaxed);
}

float ParameterSmoother::target() const {
  return target_.load(std::memory_order_relaxed);
}

float ParameterSmoother::current() const {
  return current_.load(std::memory_order_relaxed);
}

float ParameterSmoother::process() {
  const float target = target_.load(std::memory_order_relaxed);
  const float current = current_.load(std::memory_order_relaxed);
  const float next = target + (coefficient_ * (current - target));
  current_.store(next, std::memory_order_relaxed);
  return next;
}
