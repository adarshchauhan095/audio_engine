#pragma once

#include <algorithm>
#include <cmath>

#include "Biquad.h"
#include "NoiseGenerator.h"
#include "Phase2Config.h"

// Phase2 modulation generator (mono). The router handles crossfades and
// post-filtering; this focuses only on generating the raw signal for the
// selected modulation mode.
class ModulationEngine {
public:
  void init(float sampleRate) {
    sampleRate_ = std::max(1.0f, sampleRate);
    reset();
  }

  void reset() {
    phase_ = 0.0f;
    lfoPhase_ = 0.0f;
    noise_.seed(0xC0FFEEu);
    nbnBand_.reset();
    nbnBand_.setBypass();
  }

  // Generate one mono sample for the given config. baseFreq/baseAmp/intensity
  // are expected already validated by the caller.
  float process(const Phase2Config& c) {
    const float depth = std::clamp(c.depth, 0.0f, 1.0f);
    const float rateHz = std::max(0.0f, c.rateHz);

    const float lfo = std::sin(lfoPhase_);
    advanceLfo(rateHz);

    const float baseFreq = std::max(0.0f, c.baseFreq);
    const float baseAmp = std::clamp(c.baseAmp, 0.0f, 1.0f);
    const float intensity = std::clamp(c.intensity, 0.0f, 1.0f);

    switch (c.modulation) {
    case Phase2Config::ModulationType::Bypass: {
      const float s = sineAt(baseFreq);
      return (baseAmp * intensity) * s;
    }
    case Phase2Config::ModulationType::AM: {
      const float s = sineAt(baseFreq);
      // Keep gain in [1-depth, 1] (no over-boost), using 0..1 LFO.
      const float lfo01 = 0.5f * (1.0f + lfo);
      const float gain = (1.0f - depth) + depth * lfo01;
      return (baseAmp * intensity * gain) * s;
    }
    case Phase2Config::ModulationType::FM: {
      // Deviation cap: depth * min(500, 5% of carrier).
      const float cap = std::min(500.0f, 0.05f * baseFreq);
      const float dev = depth * cap;
      const float instHz = std::max(0.0f, baseFreq + dev * lfo);
      const float s = sineAt(instHz);
      return (baseAmp * intensity) * s;
    }
    case Phase2Config::ModulationType::NBN: {
      // NBN uses bandpass-filtered noise centered around baseFreq.
      float q = c.q;
      if (c.bandwidthHz > 0.0f) {
        const float bw = std::max(1.0f, c.bandwidthHz);
        q = std::max(0.3f, baseFreq / bw);
      }
      q = std::max(0.3f, q);
      // Update BP coefficients at control-rate (per-sample is ok for Phase2 lab,
      // but still cheap; can be optimized later).
      nbnBand_.setBandPass(sampleRate_, baseFreq, q);

      const float n = noise_.next();
      const float bp = nbnBand_.process(n);
      return (baseAmp * intensity) * bp;
    }
    default:
      return 0.0f;
    }
  }

private:
  void advanceLfo(float rateHz) {
    const float w = 2.0f * static_cast<float>(M_PI) * (rateHz / sampleRate_);
    lfoPhase_ += w;
    if (lfoPhase_ > 2.0f * static_cast<float>(M_PI)) lfoPhase_ -= 2.0f * static_cast<float>(M_PI);
  }

  float sineAt(float hz) {
    const float f = std::max(0.0f, hz);
    const float w = 2.0f * static_cast<float>(M_PI) * (f / sampleRate_);
    phase_ += w;
    if (phase_ > 2.0f * static_cast<float>(M_PI)) phase_ -= 2.0f * static_cast<float>(M_PI);
    return std::sin(phase_);
  }

  float sampleRate_ = 48000.0f;
  float phase_ = 0.0f;
  float lfoPhase_ = 0.0f;
  NoiseGenerator noise_;
  Biquad nbnBand_;
};

