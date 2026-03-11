#include "TherapyRouter.h"

void TherapyRouter::init(double sampleRate) {
  subthreshold_.init(sampleRate);
  rmp_.init(sampleRate);
  pip_.init(sampleRate);
  sidebands_.init(sampleRate);
  binaural_.init(sampleRate);
}

void TherapyRouter::updateConfig(const TherapyConfig &config) {
  config_ = config;
}

bool TherapyRouter::isActive() const {
  return config_.enableSubthreshold || config_.enableRMP || config_.enablePIP ||
         config_.enableSidebands || config_.enableBinaural;
}

StereoSample TherapyRouter::process(double baseFreq, float baseAmp) {
  StereoSample out{0.0f, 0.0f};
  if (!isActive())
    return out;

  float amp = baseAmp * config_.therapyIntensity;

  if (config_.enableSubthreshold) {
    float s = subthreshold_.process(baseFreq, amp);
    out.left += s;
    out.right += s;
  }

  if (config_.enableRMP) {
    float s = rmp_.process(baseFreq, amp, config_.rmpDepth, config_.rmpRate);
    out.left += s;
    out.right += s;
  }

  if (config_.enablePIP) {
    float s =
        pip_.process(baseFreq, amp, config_.pipInterval, config_.pipDuration);
    out.left += s;
    out.right += s;
  }

  if (config_.enableSidebands) {
    float s = sidebands_.process(baseFreq, amp, config_.sidebandOffset,
                                 config_.sidebandIntensity);
    out.left += s;
    out.right += s;
  }

  if (config_.enableBinaural) {
    StereoSample b = binaural_.process(baseFreq, amp, config_.binauralOffset);
    out.left += b.left;
    out.right += b.right;
  }

  return out;
}
