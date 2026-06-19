#include "GeneratorTests.h"
#include "TestUtils.h"
#include "../modules/PhaseBreakerOp.h"
#include "../modules/AntiCorrelationOp.h"
#include "../modules/ContrastRemapOp.h"
#include "../modules/SalienceScramblerOp.h"
#include "../modules/NullModelOp.h"

namespace phase5 {
namespace tests {

constexpr double kSampleRate = 48000.0;
// Generate 3 seconds of audio
constexpr int kNumSamples = static_cast<int>(kSampleRate * 3.0);

void GeneratorTests::runAll() {
    testPhaseBreaker();
    testAntiCorrelation();
    testContrastRemap();
    testSalienceScrambler();
    testNullModel();
}

void GeneratorTests::testPhaseBreaker() {
    PhaseBreakerOp op;
    op.init(kSampleRate);

    PhaseBreakerParams params;
    params.baseFrequency = 440.0f;
    params.driftAmount = 20.0f;
    params.driftSpeed = 0.5f;
    params.phaseJitter = 0.1f;
    params.amplitude = 0.5f;

    auto buffer = TestUtils::generateBuffer(kNumSamples, [&]() {
        return op.process(params);
    });

    bool ok = TestUtils::validateBuffer(buffer, -1.0f, 1.0f);
    TestUtils::printResult("PhaseBreakerTest", ok);
}

void GeneratorTests::testAntiCorrelation() {
    AntiCorrelationOp op;
    op.init(kSampleRate);

    AntiCorrelationParams params;
    params.baseFrequency = 440.0f;
    params.inversionDepth = 0.5f;
    params.delayMs = 15.0f;
    params.amplitude = 0.5f;

    auto buffer = TestUtils::generateBuffer(kNumSamples, [&]() {
        return op.process(params);
    });

    bool ok = TestUtils::validateBuffer(buffer, -1.0f, 1.0f);
    TestUtils::printResult("AntiCorrelationTest", ok);
}

void GeneratorTests::testContrastRemap() {
    ContrastRemapOp op;
    op.init(kSampleRate);

    ContrastRemapParams params;
    params.baseFrequency = 440.0f;
    params.contrastShift = 10.0f;
    params.contrastWidth = 0.5f;
    params.modulationSpeed = 2.0f;
    params.amplitude = 0.5f;

    auto buffer = TestUtils::generateBuffer(kNumSamples, [&]() {
        return op.process(params);
    });

    bool ok = TestUtils::validateBuffer(buffer, -1.0f, 1.0f);
    TestUtils::printResult("ContrastRemapTest", ok);
}

void GeneratorTests::testSalienceScrambler() {
    SalienceScramblerOp op;
    op.init(kSampleRate);

    SalienceScramblerParams params;
    params.burstRate = 5.0f;
    params.burstLengthMs = 10.0f;
    params.jitterAmount = 0.05f;
    params.amplitude = 0.5f;

    auto buffer = TestUtils::generateBuffer(kNumSamples, [&]() {
        return op.process(params);
    });

    bool ok = TestUtils::validateBuffer(buffer, -1.0f, 1.0f);
    TestUtils::printResult("SalienceScramblerTest", ok);
}

void GeneratorTests::testNullModel() {
    NullModelOp op;
    op.init(kSampleRate);

    NullModelParams params;
    params.noiseFloor = 0.2f;
    params.stability = 0.9f;
    params.amplitude = 0.2f;

    auto buffer = TestUtils::generateBuffer(kNumSamples, [&]() {
        return op.process(params);
    });

    bool ok = TestUtils::validateBuffer(buffer, -1.0f, 1.0f);
    TestUtils::printResult("NullModelTest", ok);
}

} // namespace tests
} // namespace phase5
