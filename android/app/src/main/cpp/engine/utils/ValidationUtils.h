#pragma once

#include <algorithm>
#include <cmath>

namespace utils {

// Centralized safety validation for DSP parameters and signals.
// Ensures real-time safety, prevents NaN/Inf, bounds signals.
class ValidationUtils {
public:
    // Clamp a signal between min and max bounds
    static inline float clamp(float value, float minVal, float maxVal) {
        if (std::isnan(value)) return 0.0f;
        if (value < minVal) return minVal;
        if (value > maxVal) return maxVal;
        return value;
    }

    // Clamp signal specifically to audio [-1.0, 1.0] range
    static inline float clampAudio(float value) {
        return clamp(value, -1.0f, 1.0f);
    }

    // Sanitize sample (remove NaN/Inf)
    static inline float sanitize(float value) {
        if (std::isnan(value) || std::isinf(value)) {
            return 0.0f;
        }
        return value;
    }

    // Check if frequency is within safe audio range (1 Hz to 20000 Hz)
    static inline float clampFrequency(float freq) {
        return clamp(freq, 1.0f, 20000.0f);
    }

    // Safely bounded amplitude
    static inline float clampAmplitude(float amp, float maxAllowed = 1.0f) {
        return clamp(amp, 0.0f, maxAllowed);
    }
};

} // namespace utils
