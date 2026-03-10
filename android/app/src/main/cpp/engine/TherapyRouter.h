#pragma once

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

    StereoSample process(double baseFreq, float baseAmp);

private:
    TherapyConfig config_;
    
    SubthresholdModule subthreshold_;
    RMPModule rmp_;
    PIPModule pip_;
    SidebandModule sidebands_;
    BinauralModule binaural_;
};
