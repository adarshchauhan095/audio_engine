#pragma once

#include <atomic>

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
