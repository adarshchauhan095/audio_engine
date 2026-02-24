#pragma once

#include <atomic>

/// Sample-accurate one-pole ramp for parameter updates.
///
/// [setTarget] is thread-safe (atomic); [process] runs on the audio thread
/// and advances one sample toward the target per call. Used for amplitude
/// and transport to avoid zipper noise and clicks during rapid UI changes.
class ParameterSmoother {
public:
  void setSmoothingTimeMs(float timeMs, float sampleRate);
  void reset(float value);
  void setTarget(float value);
  float target() const;
  float current() const;
  float process();

private:
  std::atomic<float> current_{0.0f};
  std::atomic<float> target_{0.0f};
  float coefficient_ = 0.0f;
};
