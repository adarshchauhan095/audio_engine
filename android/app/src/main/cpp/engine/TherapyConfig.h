#pragma once

struct TherapyConfig {
    bool enableSubthreshold = false;
    bool enableRMP = false;
    bool enablePIP = false;
    bool enableSidebands = false;
    bool enableBinaural = false;

    float therapyIntensity = 0.5f;

    // We can add specific parameters later if needed.
    // The main engine's setFrequency / setAmplitude is used as base.
};
