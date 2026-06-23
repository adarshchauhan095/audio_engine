#pragma once

#include <vector>
#include <string>

namespace phase5 {
namespace tests {

class TestUtils {
public:
    // Generate a buffer using a function callback
    template<typename Func>
    static std::vector<float> generateBuffer(int numSamples, Func processSample) {
        std::vector<float> buffer(numSamples);
        for (int i = 0; i < numSamples; ++i) {
            buffer[i] = processSample();
        }
        return buffer;
    }

    // Validates that no NaN or Inf is present, and signal is bounded
    static bool validateBuffer(const std::vector<float>& buffer, float minVal = -1.0f, float maxVal = 1.0f);

    typedef void (*LogCallback)(const char*);
    // Prints success or failure message
    static void printResult(const std::string& testName, bool success, LogCallback cb = nullptr);
};

} // namespace tests
} // namespace phase5
