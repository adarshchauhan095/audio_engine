#pragma once

namespace phase5 {

struct PhaseBreakerParams {
    float baseFrequency = 6200.0f;
    float driftAmount = 0.0f;
    float driftSpeed = 0.0f;
    float phaseJitter = 0.0f;
    float amplitude = 0.0f;
};

struct AntiCorrelationParams {
    float baseFrequency = 6200.0f;
    float inversionDepth = 0.0f;
    float delayMs = 0.0f;
    float amplitude = 0.0f;
};

struct ContrastRemapParams {
    float baseFrequency = 6200.0f;
    float contrastWidth = 0.0f;
    float contrastShift = 0.0f;
    float modulationSpeed = 0.0f;
    float amplitude = 0.0f;
};

struct SalienceScramblerParams {
    float burstRate = 0.0f;
    float burstLengthMs = 0.0f;
    float jitterAmount = 0.0f;
    float amplitude = 0.0f;
};

struct NullModelParams {
    float amplitude = 0.0f;
    float noiseFloor = 0.0f;
    float stability = 0.0f;
};

} // namespace phase5
