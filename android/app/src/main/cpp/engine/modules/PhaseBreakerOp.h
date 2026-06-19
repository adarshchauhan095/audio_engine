#pragma once

#include "PhaseBreakerGenerator.h"
#include "GeneratorParams.h"
#include "../utils/ValidationUtils.h"

namespace phase5 {

class PhaseBreakerOp {
public:
    void init(double sampleRate) {
        gen_.init(sampleRate);
    }

    void reset() {
        gen_.reset();
    }

    float process(const PhaseBreakerParams& params) {
        // Validate params before generation
        PhaseBreakerParams safeParams = params;
        safeParams.baseFrequency = utils::ValidationUtils::clampFrequency(params.baseFrequency);
        safeParams.driftAmount = utils::ValidationUtils::clamp(params.driftAmount, 0.0f, 0.05f * safeParams.baseFrequency);
        safeParams.amplitude = utils::ValidationUtils::clampAmplitude(params.amplitude, 0.8f);

        float out = gen_.process(safeParams);
        return utils::ValidationUtils::clampAudio(utils::ValidationUtils::sanitize(out));
    }

private:
    PhaseBreakerGenerator gen_;
};

} // namespace phase5
