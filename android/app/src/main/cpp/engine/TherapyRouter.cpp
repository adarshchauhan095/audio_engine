#include "TherapyRouter.h"
#include <cmath>

void TherapyRouter::init(double sampleRate) {
  sampleRate_ = static_cast<float>(sampleRate);
  subthreshold_.init(sampleRate);
  rmp_.init(sampleRate);
  pip_.init(sampleRate);
  sidebands_.init(sampleRate);
  binaural_.init(sampleRate);
  phase5Registry_.init(sampleRate);

  subthresholdGainSmoother_.setSmoothingTimeMs(20.0f, sampleRate_);
  rmpGainSmoother_.setSmoothingTimeMs(20.0f, sampleRate_);
  pipGainSmoother_.setSmoothingTimeMs(20.0f, sampleRate_);
  sidebandsGainSmoother_.setSmoothingTimeMs(20.0f, sampleRate_);
  binauralGainSmoother_.setSmoothingTimeMs(20.0f, sampleRate_);
  intensitySmoother_.setSmoothingTimeMs(80.0f, sampleRate_);

  subthresholdGainSmoother_.reset(0.0f);
  rmpGainSmoother_.reset(0.0f);
  pipGainSmoother_.reset(0.0f);
  sidebandsGainSmoother_.reset(0.0f);
  binauralGainSmoother_.reset(0.0f);
  intensitySmoother_.reset(0.0f);
}

void TherapyRouter::resetAllModulePhases() {
  subthreshold_.resetPhases();
  rmp_.reset();
  pip_.reset();
  sidebands_.resetPhases();
  binaural_.resetPhases();
  phase5Registry_.reset();
}

void TherapyRouter::resetModuleGains() {
  subthresholdGainSmoother_.reset(0.0f);
  rmpGainSmoother_.reset(0.0f);
  pipGainSmoother_.reset(0.0f);
  sidebandsGainSmoother_.reset(0.0f);
  binauralGainSmoother_.reset(0.0f);
  intensitySmoother_.reset(0.0f);
  pipResetPending_ = false;
  pipTargetEnableAfterReset_ = false;
  binauralResetPending_ = false;
}

void TherapyRouter::updateConfig(const TherapyConfig &config) {
  bool wasActive = isActive();
  const TherapyConfig prev = config_;
  config_ = config;
  intensitySmoother_.setTarget(config_.therapyIntensity);
  enableSubthreshold_.store(config_.enableSubthreshold, std::memory_order_release);
  enableRMP_.store(config_.enableRMP, std::memory_order_release);
  enablePIP_.store(config_.enablePIP, std::memory_order_release);
  enableSidebands_.store(config_.enableSidebands, std::memory_order_release);
  enableBinaural_.store(config_.enableBinaural, std::memory_order_release);

  subthresholdGainSmoother_.setTarget(config_.enableSubthreshold ? 1.0f : 0.0f);
  rmpGainSmoother_.setTarget(config_.enableRMP ? 1.0f : 0.0f);
  sidebandsGainSmoother_.setTarget(config_.enableSidebands ? 1.0f : 0.0f);

  if (config_.enableBinaural) {
    binauralResetPending_ = false;
    binauralGainSmoother_.setTarget(1.0f);
  } else if (prev.enableBinaural) {
    binauralResetPending_ = true;
    binauralGainSmoother_.setTarget(0.0f);
  } else if (!binauralResetPending_) {
    binauralGainSmoother_.setTarget(0.0f);
  }

  // PIP gain is special-cased to allow clickless resets on parameter changes.
  // Default: follow enabled state.
  if (!pipResetPending_) {
    pipGainSmoother_.setTarget(config_.enablePIP ? 1.0f : 0.0f);
  }

  const bool nowActive = isActive();
  if (wasActive && !nowActive) {
    rmp_.reset();
    pip_.reset();
    pipResetPending_ = false;
    pipTargetEnableAfterReset_ = false;
    if (!binauralResetPending_) {
      binaural_.resetPhases();
    }
  }

  // If PIP parameters change while PIP is enabled, schedule a clickless reset:
  // fade PIP to silence, reset, then fade back in.
  if (enablePIP_.load(std::memory_order_acquire)) {
    const bool intervalChanged =
        std::fabs(prev.pipInterval - config_.pipInterval) > 1e-6f;
    const bool durationChanged =
        std::fabs(prev.pipDuration - config_.pipDuration) > 1e-6f;
    if ((intervalChanged || durationChanged) && !pipResetPending_) {
      pipResetPending_ = true;
      pipTargetEnableAfterReset_ = true;
      pipGainSmoother_.setTarget(0.0f);
    }
  }
}

bool TherapyRouter::isActive() const {
  return enableSubthreshold_.load(std::memory_order_acquire) || subthresholdGainSmoother_.target() > 0.0f || subthresholdGainSmoother_.current() > 0.001f ||
         enableRMP_.load(std::memory_order_acquire) || rmpGainSmoother_.target() > 0.0f || rmpGainSmoother_.current() > 0.001f ||
         enablePIP_.load(std::memory_order_acquire) || pipGainSmoother_.target() > 0.0f || pipGainSmoother_.current() > 0.001f ||
         enableSidebands_.load(std::memory_order_acquire) || sidebandsGainSmoother_.target() > 0.0f || sidebandsGainSmoother_.current() > 0.001f ||
         enableBinaural_.load(std::memory_order_acquire) || binauralGainSmoother_.target() > 0.0f || binauralGainSmoother_.current() > 0.001f ||
         config_.enablePhaseBreaker || config_.enableAntiCorrelation || config_.enableContrastRemap || config_.enableSalienceScrambler || config_.enableNullModel;
}

StereoSample TherapyRouter::process() {
  StereoSample out{0.0f, 0.0f};
  if (!isActive())
    return out;

  // If a PIP reset is pending, wait until PIP is effectively silent, then reset
  // its internal schedule and fade back in.
  if (pipResetPending_) {
    const float pipNow = pipGainSmoother_.current();
    if (pipNow < 0.001f) {
      pip_.reset();
      pipResetPending_ = false;
      pipGainSmoother_.setTarget(pipTargetEnableAfterReset_ ? 1.0f : 0.0f);
      pipTargetEnableAfterReset_ = false;
    }
  }

  if (binauralResetPending_) {
    const float binNow = binauralGainSmoother_.current();
    if (binNow < 0.001f) {
      binaural_.resetPhases();
      binauralResetPending_ = false;
    }
  }

  const double baseFreq = config_.baseFreq;
  const float baseAmp = config_.baseAmp;
  const float intensity = intensitySmoother_.process();
  float amp = baseAmp * intensity;

  const float subM = subthresholdGainSmoother_.process();
  if (subM > 0.0f) {
    float s = subthreshold_.process(baseFreq, amp) * subM;
    out.left += s;
    out.right += s;
  }

  const float rmpM = rmpGainSmoother_.process();
  if (rmpM > 0.0f) {
    float s = rmp_.process(baseFreq, amp, config_.rmpDepth, config_.rmpRate) * rmpM;
    out.left += s;
    out.right += s;
  }

  const float pipM = pipGainSmoother_.process();
  if (pipM > 0.0f) {
    float s =
        pip_.process(baseFreq, amp, config_.pipInterval, config_.pipDuration) * pipM;
    out.left += s;
    out.right += s;
  }

  const float sbM = sidebandsGainSmoother_.process();
  if (sbM > 0.0f) {
    float s = sidebands_.process(baseFreq, amp, config_.sidebandOffset,
                                 config_.sidebandIntensity) * sbM;
    out.left += s;
    out.right += s;
  }

  const float binM = binauralGainSmoother_.process();
  if (binM > 0.0f) {
    StereoSample b = binaural_.process(baseFreq, amp, config_.binauralOffset);
    out.left += b.left * binM;
    out.right += b.right * binM;
  }

  // Phase 5.2 Expansion Layer
  // Generators are internally clamped and safe.
  float phase5Mix = phase5Registry_.process(config_);
  out.left += phase5Mix;
  out.right += phase5Mix;

  return out;
}
