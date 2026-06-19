#include "OperatorRegistry.h"

namespace phase5 {

void OperatorRegistry::init(double sampleRate) {
    phaseBreaker_.init(sampleRate);
    antiCorrelation_.init(sampleRate);
    contrastRemap_.init(sampleRate);
    salienceScrambler_.init(sampleRate);
    nullModel_.init(sampleRate);
}

void OperatorRegistry::reset() {
    phaseBreaker_.reset();
    antiCorrelation_.reset();
    contrastRemap_.reset();
    salienceScrambler_.reset();
    nullModel_.reset();
}

float OperatorRegistry::process(const TherapyConfig& config) {
    float mix = 0.0f;

    if (config.enablePhaseBreaker) {
        mix += phaseBreaker_.process(config.phaseBreakerParams);
    }
    if (config.enableAntiCorrelation) {
        mix += antiCorrelation_.process(config.antiCorrelationParams);
    }
    if (config.enableContrastRemap) {
        mix += contrastRemap_.process(config.contrastRemapParams);
    }
    if (config.enableSalienceScrambler) {
        mix += salienceScrambler_.process(config.salienceScramblerParams);
    }
    if (config.enableNullModel) {
        mix += nullModel_.process(config.nullModelParams);
    }

    return mix;
}

} // namespace phase5
