#pragma once

#include "SalienceScramblerGenerator.h"
#include "GeneratorParams.h"
#include "../utils/ValidationUtils.h"

namespace phase5 {

class SalienceScramblerOp {
public:
    void init(double sampleRate) {
        gen_.init(sampleRate);
    }

    void reset() {
        gen_.reset();
    }

    float process(const SalienceScramblerParams& params) {
        SalienceScramblerParams safeParams = params;
        safeParams.burstRate = utils::ValidationUtils::clamp(params.burstRate, 0.0f, 100.0f);
        safeParams.burstLengthMs = utils::ValidationUtils::clamp(params.burstLengthMs, 0.0f, 20.0f);
        safeParams.jitterAmount = utils::ValidationUtils::clamp(params.jitterAmount, 0.0f, 1.0f);
        safeParams.amplitude = utils::ValidationUtils::clampAmplitude(params.amplitude, 0.6f);

        float out = gen_.process(safeParams);
        return utils::ValidationUtils::clampAudio(utils::ValidationUtils::sanitize(out));
    }

private:
    SalienceScramblerGenerator gen_;
};

} // namespace phase5
