#pragma once

#include <cstdint>

// Deterministic white noise generator for audio.
// Uses xorshift32 (fast, repeatable, no allocations).
class NoiseGenerator {
public:
  void seed(uint32_t s) { state_ = (s == 0 ? 0x12345678u : s); }

  // Returns approximately [-1, 1].
  float next() {
    uint32_t x = state_;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    state_ = x;
    // Convert to [-1, 1] using top 24 bits.
    const uint32_t mant = (x >> 8) & 0x00FFFFFFu;
    const float v = static_cast<float>(mant) / 8388607.5f - 1.0f;
    return v;
  }

private:
  uint32_t state_ = 0x12345678u;
};

