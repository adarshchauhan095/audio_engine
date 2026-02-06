#pragma once
#include <atomic>

class Oscillator {
public:
  void setFrequency(float hz);
  float process();

private:
  std::atomic<float> frequency_{440.0f};
  float phase_ = 0.0f;
};
