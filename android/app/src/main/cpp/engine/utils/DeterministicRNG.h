#pragma once

#include <cstdint>

namespace utils {

// Lightweight deterministic XorShift32 RNG for real-time DSP
// Guarantees same output for same seed, no locks, no allocations.
class DeterministicRNG {
public:
    explicit DeterministicRNG(uint32_t seed = 0x12345678) {
        setSeed(seed);
    }

    void setSeed(uint32_t seed) {
        state_ = (seed == 0) ? 0x12345678 : seed;
    }

    // Returns a pseudo-random uint32
    uint32_t next() {
        uint32_t x = state_;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        state_ = x;
        return x;
    }

    // Returns a float in [0.0, 1.0]
    float nextFloat() {
        return static_cast<float>(next() & 0xFFFFFF) / static_cast<float>(0xFFFFFF);
    }

    // Returns a float in [-1.0, 1.0]
    float nextFloatSymmetric() {
        return (nextFloat() * 2.0f) - 1.0f;
    }

private:
    uint32_t state_;
};

} // namespace utils
