#pragma once

namespace phase5 {
namespace tests {

class GeneratorTests {
public:
    typedef void (*LogCallback)(const char*);
    static void runAll(LogCallback cb = nullptr);

private:
    static void testPhaseBreaker();
    static void testAntiCorrelation();
    static void testContrastRemap();
    static void testSalienceScrambler();
    static void testNullModel();
};

} // namespace tests
} // namespace phase5
