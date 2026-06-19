#pragma once

#include <atomic>

#include "TherapyConfig.h"
#include "modules/SubthresholdModule.h"
#include "modules/RMPModule.h"
#include "modules/PIPModule.h"
#include "modules/SidebandModule.h"
#include "modules/BinauralModule.h"
#include "modules/OperatorRegistry.h"
#include "ParameterSmoother.h"

class TherapyRouter {
public:
    void init(double sampleRate);
    void updateConfig(const TherapyConfig& config);
    void resetAllModulePhases();
    /// Zero module enable gains before a new session fade-in.
    void resetModuleGains();
    bool isActive() const;

    StereoSample process();

private:
    float sampleRate_ = 48000.0f;
    ParameterSmoother subthresholdGainSmoother_;
    ParameterSmoother rmpGainSmoother_;
    ParameterSmoother pipGainSmoother_;
    ParameterSmoother sidebandsGainSmoother_;
    ParameterSmoother binauralGainSmoother_;
    ParameterSmoother intensitySmoother_;

    TherapyConfig config_;
    std::atomic<bool> enableSubthreshold_{false};
    std::atomic<bool> enableRMP_{false};
    std::atomic<bool> enablePIP_{false};
    std::atomic<bool> enableSidebands_{false};
    std::atomic<bool> enableBinaural_{false};

    SubthresholdModule subthreshold_;
    RMPModule rmp_;
    PIPModule pip_;
    SidebandModule sidebands_;
    BinauralModule binaural_;

    phase5::OperatorRegistry phase5Registry_;

    // Clickless PIP param-change handling:
    // when interval/duration changes, fade PIP module to silence, reset its
    // schedule, then fade back in.
    bool pipResetPending_ = false;
    bool pipTargetEnableAfterReset_ = false;

    // Fade binaural out, reset oscillator phases at silence, then release.
    bool binauralResetPending_ = false;
};
