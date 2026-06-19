#include "TestUtils.h"
#include <iostream>
#include <cmath>

namespace phase5 {
namespace tests {

bool TestUtils::validateBuffer(const std::vector<float>& buffer, float minVal, float maxVal) {
    for (float sample : buffer) {
        if (std::isnan(sample) || std::isinf(sample)) {
            return false;
        }
        if (sample < minVal || sample > maxVal) {
            return false;
        }
    }
    return true;
}

void TestUtils::printResult(const std::string& testName, bool success) {
    if (success) {
        std::cout << "[SUCCESS] " << testName << " passed.\n";
    } else {
        std::cerr << "[FAILED]  " << testName << " failed.\n";
    }
}

} // namespace tests
} // namespace phase5
