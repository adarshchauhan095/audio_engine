#pragma once

#include <cstdint>

// Phase 2 configuration for AM/FM/NBN + filters.
//
// This is intentionally independent from TherapyConfig to avoid affecting
// existing therapy modules and their FFI signatures.
struct Phase2Config {
  enum class ModulationType : int32_t { Bypass = 0, AM = 1, FM = 2, NBN = 3 };
  enum class FilterType : int32_t { Bypass = 0, LowPass = 1, HighPass = 2, BandPass = 3 };

  bool enabled = false;

  // Base carrier / center frequency.
  float baseFreq = 6200.0f;
  float baseAmp = 0.2f;

  // Master intensity [0..1] applied after synthesis.
  float intensity = 0.5f;

  // Modulation params
  ModulationType modulation = ModulationType::Bypass;
  float depth = 0.0f; // [0..1]
  float rateHz = 4.0f;

  // For NBN: if bandwidthHz > 0, Q is derived from baseFreq/bandwidthHz.
  float bandwidthHz = 0.0f;

  // Filter params (post stage). For BP, cutoffHz is treated as centerHz.
  FilterType filter = FilterType::Bypass;
  float cutoffHz = 6000.0f;
  float q = 1.0f; // >= 0.3 recommended

  // Transition smoothing (crossfade) in milliseconds.
  float transitionMs = 100.0f;
};

