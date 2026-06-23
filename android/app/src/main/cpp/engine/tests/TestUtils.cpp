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

void TestUtils::printResult(const std::string& testName, bool success, LogCallback cb) {
    std::string msg;
    if (success) {
        msg = "[SUCCESS] " + testName + " passed.";
    } else {
        msg = "[FAILED]  " + testName + " failed.";
    }
    std::cout << msg << "\n";
    if (cb) {
        cb(msg.c_str());
    }
}

} // namespace tests
} // namespace phase5
