#pragma once

#include <atomic>

#include "TherapyConfig.h"
#include "modules/SubthresholdModule.h"
#include "modules/RMPModule.h"
#include "modules/PIPModule.h"
#include "modules/SidebandModule.h"
#include "modules/BinauralModule.h"

class TherapyRouter {
public:
    void init(double sampleRate);
    void updateConfig(const TherapyConfig& config);
    bool isActive() const;

    StereoSample process();

    /// Read-only normalized meters for the therapy modules.
    ///
    /// index mapping:
    /// 0 = Subthreshold
    /// 1 = RMP
    /// 2 = PIP
    /// 3 = Sidebands (SSS)
    /// 4 = Binaural
    float moduleMeter(int index) const;

private:
    TherapyConfig config_;
    std::atomic<bool> enableSubthreshold_{false};
    std::atomic<bool> enableRMP_{false};
    std::atomic<bool> enablePIP_{false};
    std::atomic<bool> enableSidebands_{false};
    std::atomic<bool> enableBinaural_{false};

    // Module meters (updated from the audio thread).
    std::atomic<float> meterSubthreshold_{0.0f};
    std::atomic<float> meterRmp_{0.0f};
    std::atomic<float> meterPip_{0.0f};
    std::atomic<float> meterSidebands_{0.0f};
    std::atomic<float> meterBinaural_{0.0f};

    // Meter accumulation (audio thread only; do not need atomics).
    float meterAccumSubthreshold_ = 0.0f;
    float meterAccumRmp_ = 0.0f;
    float meterAccumPip_ = 0.0f;
    float meterAccumSidebands_ = 0.0f;
    float meterAccumBinaural_ = 0.0f;
    uint32_t meterFramesAccum_ = 0;
    static constexpr uint32_t kMeterUpdateFrames = 256;

    SubthresholdModule subthreshold_;
    RMPModule rmp_;
    PIPModule pip_;
    SidebandModule sidebands_;
    BinauralModule binaural_;
};
