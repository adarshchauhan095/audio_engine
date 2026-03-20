#include "TherapyRouter.h"
#include <algorithm>
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
  const float amp = baseAmp * config_.therapyIntensity;
  const float meterScale = std::max(1e-6f, baseAmp);

  float meterSub = 0.0f;
  float meterRmp = 0.0f;
  float meterPip = 0.0f;
  float meterSidebands = 0.0f;
  float meterBinaural = 0.0f;

  if (enableSubthreshold_.load(std::memory_order_acquire)) {
    float s = subthreshold_.process(baseFreq, amp);
    out.left += s;
    out.right += s;
    meterSub = std::fabs(s);
  }

  if (enableRMP_.load(std::memory_order_acquire)) {
    float s = rmp_.process(baseFreq, amp, config_.rmpDepth, config_.rmpRate);
    out.left += s;
    out.right += s;
    meterRmp = std::fabs(s);
  }

  if (enablePIP_.load(std::memory_order_acquire)) {
    float s =
        pip_.process(baseFreq, amp, config_.pipInterval, config_.pipDuration);
    out.left += s;
    out.right += s;
    meterPip = std::fabs(s);
  }

  if (enableSidebands_.load(std::memory_order_acquire)) {
    float s = sidebands_.process(baseFreq, amp, config_.sidebandOffset,
                                 config_.sidebandIntensity);
    out.left += s;
    out.right += s;
    meterSidebands = std::fabs(s);
  }

  if (enableBinaural_.load(std::memory_order_acquire)) {
    StereoSample b = binaural_.process(baseFreq, amp, config_.binauralOffset);
    out.left += b.left;
    out.right += b.right;
    meterBinaural = 0.5f * (std::fabs(b.left) + std::fabs(b.right));
  }

  // Update module meters (lightweight decimated accumulation).
  meterAccumSubthreshold_ += meterSub;
  meterAccumRmp_ += meterRmp;
  meterAccumPip_ += meterPip;
  meterAccumSidebands_ += meterSidebands;
  meterAccumBinaural_ += meterBinaural;
  ++meterFramesAccum_;

  if (meterFramesAccum_ >= kMeterUpdateFrames) {
    const float invFrames = 1.0f / static_cast<float>(meterFramesAccum_);
    // Normalize by base amplitude so meter follows therapy intensity changes.
    meterSubthreshold_.store(
        std::fmin(1.0f, (meterAccumSubthreshold_ * invFrames) / meterScale),
        std::memory_order_relaxed);
    meterRmp_.store(
        std::fmin(1.0f, (meterAccumRmp_ * invFrames) / meterScale),
        std::memory_order_relaxed);
    meterPip_.store(
        std::fmin(1.0f, (meterAccumPip_ * invFrames) / meterScale),
        std::memory_order_relaxed);
    meterSidebands_.store(
        std::fmin(1.0f, (meterAccumSidebands_ * invFrames) / meterScale),
        std::memory_order_relaxed);
    meterBinaural_.store(
        std::fmin(1.0f, (meterAccumBinaural_ * invFrames) / meterScale),
        std::memory_order_relaxed);

    meterAccumSubthreshold_ = 0.0f;
    meterAccumRmp_ = 0.0f;
    meterAccumPip_ = 0.0f;
    meterAccumSidebands_ = 0.0f;
    meterAccumBinaural_ = 0.0f;
    meterFramesAccum_ = 0;
  }

  return out;
}

float TherapyRouter::moduleMeter(int index) const {
  switch (index) {
  case 0:
    return meterSubthreshold_.load(std::memory_order_relaxed);
  case 1:
    return meterRmp_.load(std::memory_order_relaxed);
  case 2:
    return meterPip_.load(std::memory_order_relaxed);
  case 3:
    return meterSidebands_.load(std::memory_order_relaxed);
  case 4:
    return meterBinaural_.load(std::memory_order_relaxed);
  default:
    return 0.0f;
  }
}
