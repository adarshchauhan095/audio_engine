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

private:
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
};
