#pragma once

#include <algorithm>
#include <cmath>

// RBJ audio EQ cookbook biquad.
class Biquad {
public:
  enum class Type { Bypass, LowPass, HighPass, BandPass };

  void reset() {
    z1_ = 0.0f;
    z2_ = 0.0f;
  }

  void setBypass() {
    type_ = Type::Bypass;
    // Coeffs not used in bypass.
  }

  void setLowPass(float sampleRate, float cutoffHz, float q) {
    type_ = Type::LowPass;
    setCookbook(sampleRate, cutoffHz, q, Type::LowPass);
  }

  void setHighPass(float sampleRate, float cutoffHz, float q) {
    type_ = Type::HighPass;
    setCookbook(sampleRate, cutoffHz, q, Type::HighPass);
  }

  void setBandPass(float sampleRate, float centerHz, float q) {
    type_ = Type::BandPass;
    setCookbook(sampleRate, centerHz, q, Type::BandPass);
  }

  float process(float x) {
    if (type_ == Type::Bypass) return x;

    // Direct Form II transposed
    const float y = b0_ * x + z1_;
    z1_ = b1_ * x + z2_ - a1_ * y;
    z2_ = b2_ * x - a2_ * y;
    return y;
  }

  Type type() const { return type_; }

private:
  void setCookbook(float sampleRate, float freqHz, float q, Type type) {
    const float sr = std::max(1.0f, sampleRate);
    const float f = std::clamp(freqHz, 5.0f, 0.49f * sr);
    const float Q = std::max(0.001f, q);

    const float w0 = 2.0f * static_cast<float>(M_PI) * (f / sr);
    const float cw = std::cos(w0);
    const float sw = std::sin(w0);
    const float alpha = sw / (2.0f * Q);

    float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f, a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;

    switch (type) {
    case Type::LowPass:
      b0 = (1.0f - cw) * 0.5f;
      b1 = 1.0f - cw;
      b2 = (1.0f - cw) * 0.5f;
      a0 = 1.0f + alpha;
      a1 = -2.0f * cw;
      a2 = 1.0f - alpha;
      break;
    case Type::HighPass:
      b0 = (1.0f + cw) * 0.5f;
      b1 = -(1.0f + cw);
      b2 = (1.0f + cw) * 0.5f;
      a0 = 1.0f + alpha;
      a1 = -2.0f * cw;
      a2 = 1.0f - alpha;
      break;
    case Type::BandPass:
      // Constant skirt gain, peak gain = Q
      b0 = sw * 0.5f;
      b1 = 0.0f;
      b2 = -sw * 0.5f;
      a0 = 1.0f + alpha;
      a1 = -2.0f * cw;
      a2 = 1.0f - alpha;
      break;
    case Type::Bypass:
    default:
      setBypass();
      return;
    }

    const float invA0 = 1.0f / a0;
    b0_ = b0 * invA0;
    b1_ = b1 * invA0;
    b2_ = b2 * invA0;
    a1_ = a1 * invA0;
    a2_ = a2 * invA0;
  }

  Type type_ = Type::Bypass;
  float b0_ = 1.0f, b1_ = 0.0f, b2_ = 0.0f;
  float a1_ = 0.0f, a2_ = 0.0f;
  float z1_ = 0.0f, z2_ = 0.0f;
};

