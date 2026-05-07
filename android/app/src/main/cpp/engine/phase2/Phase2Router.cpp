#include "Phase2Router.h"

#include <algorithm>
#include <cmath>

void Phase2Router::init(double sampleRate) {
  sampleRate_ = static_cast<float>(sampleRate <= 0.0 ? 48000.0 : sampleRate);

  a_.mod.init(sampleRate_);
  b_.mod.init(sampleRate_);
  a_.post.reset();
  b_.post.reset();
  a_.post.setBypass();
  b_.post.setBypass();

  transitionMix_.setSmoothingTimeMs(100.0f, sampleRate_);
  transitionMix_.reset(1.0f);
  transitioning_ = false;
  usingB_ = false;
}

Phase2Config Phase2Router::snapshotConfig() const {
  Phase2Config c;
  c.enabled = enabled_.load(std::memory_order_acquire);
  c.modulation = static_cast<Phase2Config::ModulationType>(
      modulation_.load(std::memory_order_acquire));
  c.filter = static_cast<Phase2Config::FilterType>(
      filter_.load(std::memory_order_acquire));
  c.baseFreq = baseFreq_.load(std::memory_order_acquire);
  c.baseAmp = baseAmp_.load(std::memory_order_acquire);
  c.intensity = intensity_.load(std::memory_order_acquire);
  c.depth = depth_.load(std::memory_order_acquire);
  c.rateHz = rateHz_.load(std::memory_order_acquire);
  c.bandwidthHz = bandwidthHz_.load(std::memory_order_acquire);
  c.cutoffHz = cutoffHz_.load(std::memory_order_acquire);
  c.q = q_.load(std::memory_order_acquire);
  c.transitionMs = transitionMs_.load(std::memory_order_acquire);
  return c;
}

void Phase2Router::updateConfig(const Phase2Config& config) {
  enabled_.store(config.enabled, std::memory_order_release);
  modulation_.store(static_cast<int32_t>(config.modulation), std::memory_order_release);
  filter_.store(static_cast<int32_t>(config.filter), std::memory_order_release);

  baseFreq_.store(config.baseFreq, std::memory_order_release);
  baseAmp_.store(config.baseAmp, std::memory_order_release);
  intensity_.store(config.intensity, std::memory_order_release);
  depth_.store(config.depth, std::memory_order_release);
  rateHz_.store(config.rateHz, std::memory_order_release);
  bandwidthHz_.store(config.bandwidthHz, std::memory_order_release);
  cutoffHz_.store(config.cutoffHz, std::memory_order_release);
  q_.store(config.q, std::memory_order_release);
  transitionMs_.store(config.transitionMs, std::memory_order_release);

  // Start a deterministic crossfade when modulation/filter mode changes.
  // (Other params are safe to update continuously.)
  const Phase2Config snap = snapshotConfig();
  Voice& active = usingB_ ? b_ : a_;
  const bool modeChanged =
      active.config.modulation != snap.modulation ||
      active.config.filter != snap.filter;

  if (modeChanged) {
    // Prepare inactive voice with the new modes.
    Voice& next = usingB_ ? a_ : b_;
    next.config = snap;
    next.mod.reset();
    next.mod.init(sampleRate_);
    next.post.reset();
    applyPostFilter(next);

    const float ms = std::clamp(snap.transitionMs, 50.0f, 200.0f);
    transitionMix_.setSmoothingTimeMs(ms, sampleRate_);
    transitionMix_.reset(0.0f);
    transitionMix_.setTarget(1.0f);
    transitioning_ = true;
  } else {
    // Update active config continuously (keeps phases continuous).
    active.config = snap;
    applyPostFilter(active);
  }
}

bool Phase2Router::isActive() const {
  if (!enabled_.load(std::memory_order_acquire)) return false;
  // Consider active while transitioning too.
  return true;
}

void Phase2Router::applyPostFilter(Voice& v) {
  const float q = std::max(0.3f, v.config.q);
  const float f = v.config.cutoffHz;
  switch (v.config.filter) {
  case Phase2Config::FilterType::Bypass:
    v.post.setBypass();
    break;
  case Phase2Config::FilterType::LowPass:
    v.post.setLowPass(sampleRate_, f, q);
    break;
  case Phase2Config::FilterType::HighPass:
    v.post.setHighPass(sampleRate_, f, q);
    break;
  case Phase2Config::FilterType::BandPass:
    v.post.setBandPass(sampleRate_, f, q);
    break;
  default:
    v.post.setBypass();
    break;
  }
}

StereoSample Phase2Router::process() {
  StereoSample out{0.0f, 0.0f};
  if (!isActive()) return out;

  Voice& active = usingB_ ? b_ : a_;
  if (!transitioning_) {
    float x = active.mod.process(active.config);
    x = active.post.process(x);
    out.left = x;
    out.right = x;
    return out;
  }

  Voice& next = usingB_ ? a_ : b_;
  const float mix = transitionMix_.process();
  const float inv = 1.0f - mix;

  float xa = active.mod.process(active.config);
  xa = active.post.process(xa);
  float xb = next.mod.process(next.config);
  xb = next.post.process(xb);

  const float x = xa * inv + xb * mix;
  out.left = x;
  out.right = x;

  if (mix > 0.999f) {
    usingB_ = !usingB_;
    transitioning_ = false;
    // Ensure the new active voice config is fresh snapshot.
    Voice& nowActive = usingB_ ? b_ : a_;
    nowActive.config = snapshotConfig();
    applyPostFilter(nowActive);
    transitionMix_.reset(1.0f);
  }

  return out;
}

