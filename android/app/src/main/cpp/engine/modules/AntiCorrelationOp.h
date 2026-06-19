#pragma once

#include "AntiCorrelationGenerator.h"
#include "GeneratorParams.h"
#include "../utils/ValidationUtils.h"

namespace phase5 {

class AntiCorrelationOp {
public:
    void init(double sampleRate) {
        gen_.init(sampleRate);
    }

    void reset() {
        gen_.reset();
    }

    float process(const AntiCorrelationParams& params) {
        AntiCorrelationParams safeParams = params;
        safeParams.baseFrequency = utils::ValidationUtils::clampFrequency(params.baseFrequency);
        safeParams.inversionDepth = utils::ValidationUtils::clamp(params.inversionDepth, 0.0f, 0.7f);
        safeParams.delayMs = utils::ValidationUtils::clamp(params.delayMs, 0.0f, 30.0f);
        // AntiCorrelation might have amplitude spikes if waves align perfectly, though inversion depth limits it.
        safeParams.amplitude = utils::ValidationUtils::clampAmplitude(params.amplitude, 1.0f);

        float out = gen_.process(safeParams);
        return utils::ValidationUtils::clampAudio(utils::ValidationUtils::sanitize(out));
    }

private:
    AntiCorrelationGenerator gen_;
};

} // namespace phase5
