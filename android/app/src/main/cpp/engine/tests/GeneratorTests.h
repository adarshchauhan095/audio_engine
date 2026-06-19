#pragma once

namespace phase5 {
namespace tests {

class GeneratorTests {
public:
    static void runAll();

private:
    static void testPhaseBreaker();
    static void testAntiCorrelation();
    static void testContrastRemap();
    static void testSalienceScrambler();
    static void testNullModel();
};

} // namespace tests
} // namespace phase5
