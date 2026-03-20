#include "TherapyRouter.h"
#include <cmath>

void TherapyRouter::init(double sampleRate) {
  subthreshold_.init(sampleRate);
  rmp_.init(sampleRate);
  pip_.init(sampleRate);
  sidebands_.init(sampleRate);
  binaural_.init(sampleRate);
}

void TherapyRouter::updateConfig(const TherapyConfig &config) {
  bool wasActive = isActive();
  const TherapyConfig prev = config_;
  config_ = config;
  enableSubthreshold_.store(config_.enableSubthreshold, std::memory_order_release);
  enableRMP_.store(config_.enableRMP, std::memory_order_release);
  enablePIP_.store(config_.enablePIP, std::memory_order_release);
  enableSidebands_.store(config_.enableSidebands, std::memory_order_release);
  enableBinaural_.store(config_.enableBinaural, std::memory_order_release);

  const bool nowActive = isActive();
  if (wasActive && !nowActive) {
    rmp_.reset();
    pip_.reset();
  }

  // If PIP parameters change while PIP stays enabled, reset so the new
  // interval/duration schedule takes effect immediately.
  if (enablePIP_.load(std::memory_order_acquire)) {
    const float intervalChanged =
        std::fabs(prev.pipInterval - config_.pipInterval) > 1e-6f;
    const float durationChanged =
        std::fabs(prev.pipDuration - config_.pipDuration) > 1e-6f;
    if (intervalChanged || durationChanged) {
      pip_.reset();
    }
  }
}

bool TherapyRouter::isActive() const {
  return enableSubthreshold_.load(std::memory_order_acquire) ||
         enableRMP_.load(std::memory_order_acquire) ||
         enablePIP_.load(std::memory_order_acquire) ||
         enableSidebands_.load(std::memory_order_acquire) ||
         enableBinaural_.load(std::memory_order_acquire);
}

StereoSample TherapyRouter::process() {
  StereoSample out{0.0f, 0.0f};
  if (!isActive())
    return out;

  const double baseFreq = config_.baseFreq;
  const float baseAmp = config_.baseAmp;
  float amp = baseAmp * config_.therapyIntensity;

  if (enableSubthreshold_.load(std::memory_order_acquire)) {
    float s = subthreshold_.process(baseFreq, amp);
    out.left += s;
    out.right += s;
  }

  if (enableRMP_.load(std::memory_order_acquire)) {
    float s = rmp_.process(baseFreq, amp, config_.rmpDepth, config_.rmpRate);
    out.left += s;
    out.right += s;
  }

  if (enablePIP_.load(std::memory_order_acquire)) {
    float s =
        pip_.process(baseFreq, amp, config_.pipInterval, config_.pipDuration);
    out.left += s;
    out.right += s;
  }

  if (enableSidebands_.load(std::memory_order_acquire)) {
    float s = sidebands_.process(baseFreq, amp, config_.sidebandOffset,
                                 config_.sidebandIntensity);
    out.left += s;
    out.right += s;
  }

  if (enableBinaural_.load(std::memory_order_acquire)) {
    StereoSample b = binaural_.process(baseFreq, amp, config_.binauralOffset);
    out.left += b.left;
    out.right += b.right;
  }

  return out;
}
