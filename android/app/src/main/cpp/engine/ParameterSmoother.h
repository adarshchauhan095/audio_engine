#pragma once

class ParameterSmoother {
public:
  void setTarget(float value);
  float process();

private:
  float current_ = 0.0f;
  float target_ = 0.0f;
};
