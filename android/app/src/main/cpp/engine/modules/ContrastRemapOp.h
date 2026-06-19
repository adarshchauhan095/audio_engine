#pragma once

#include "ContrastRemapGenerator.h"
#include "GeneratorParams.h"
#include "../utils/ValidationUtils.h"

namespace phase5 {

class ContrastRemapOp {
public:
    void init(double sampleRate) {
        gen_.init(sampleRate);
    }

    void reset() {
        gen_.reset();
    }

    float process(const ContrastRemapParams& params) {
        ContrastRemapParams safeParams = params;
        safeParams.baseFrequency = utils::ValidationUtils::clampFrequency(params.baseFrequency);
        safeParams.contrastShift = utils::ValidationUtils::clamp(params.contrastShift, 0.0f, 100.0f);
        // Ensure modulation speed is sane (e.g. 0 to 50 Hz)
        safeParams.modulationSpeed = utils::ValidationUtils::clamp(params.modulationSpeed, 0.0f, 50.0f);
        safeParams.amplitude = utils::ValidationUtils::clampAmplitude(params.amplitude, 0.8f);

        float out = gen_.process(safeParams);
        return utils::ValidationUtils::clampAudio(utils::ValidationUtils::sanitize(out));
    }

private:
    ContrastRemapGenerator gen_;
};

} // namespace phase5
