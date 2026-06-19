#pragma once

#include "NullModelGenerator.h"
#include "GeneratorParams.h"
#include "../utils/ValidationUtils.h"

namespace phase5 {

class NullModelOp {
public:
    void init(double sampleRate) {
        gen_.init(sampleRate);
    }

    void reset() {
        gen_.reset();
    }

    float process(const NullModelParams& params) {
        NullModelParams safeParams = params;
        safeParams.noiseFloor = utils::ValidationUtils::clamp(params.noiseFloor, 0.0f, 1.0f);
        safeParams.stability = utils::ValidationUtils::clamp(params.stability, 0.0f, 0.99f);
        safeParams.amplitude = utils::ValidationUtils::clampAmplitude(params.amplitude, 0.3f);

        float out = gen_.process(safeParams);
        return utils::ValidationUtils::clampAudio(utils::ValidationUtils::sanitize(out));
    }

private:
    NullModelGenerator gen_;
};

} // namespace phase5
