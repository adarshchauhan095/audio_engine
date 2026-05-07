#pragma once

#include <atomic>
#include <cstdint>

#include "../ParameterSmoother.h"
#include "../TherapyRouter.h" // for StereoSample type

#include "Biquad.h"
#include "ModulationEngine.h"
#include "Phase2Config.h"

class Phase2Router {
public:
  void init(double sampleRate);
  void updateConfig(const Phase2Config& config);
  bool isActive() const;

  StereoSample process();

private:
  float sampleRate_ = 48000.0f;

  // Atomic parameter targets set from updateConfig (non-audio thread).
  std::atomic<bool> enabled_{false};
  std::atomic<int32_t> modulation_{static_cast<int32_t>(Phase2Config::ModulationType::Bypass)};
  std::atomic<int32_t> filter_{static_cast<int32_t>(Phase2Config::FilterType::Bypass)};

  std::atomic<float> baseFreq_{6200.0f};
  std::atomic<float> baseAmp_{0.2f};
  std::atomic<float> intensity_{0.5f};
  std::atomic<float> depth_{0.0f};
  std::atomic<float> rateHz_{4.0f};
  std::atomic<float> bandwidthHz_{0.0f};
  std::atomic<float> cutoffHz_{6000.0f};
  std::atomic<float> q_{1.0f};
  std::atomic<float> transitionMs_{100.0f};

  struct Voice {
    Phase2Config config;
    ModulationEngine mod;
    Biquad post;
  };

  Voice a_;
  Voice b_;
  bool usingB_ = false;

  // Crossfade between voices when modulation/filter mode changes.
  bool transitioning_ = false;
  ParameterSmoother transitionMix_;

  Phase2Config snapshotConfig() const;
  void applyPostFilter(Voice& v);
};

