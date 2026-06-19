#pragma once

#include "modules/GeneratorParams.h"

struct TherapyConfig {
  bool enableSubthreshold = false;
  bool enableRMP = false;
  bool enablePIP = false;
  bool enableSidebands = false;
  bool enableBinaural = false;

  // Phase 5.2 Generators (internal only, programmatically controlled later)
  bool enablePhaseBreaker = false;
  bool enableAntiCorrelation = false;
  bool enableContrastRemap = false;
  bool enableSalienceScrambler = false;
  bool enableNullModel = false;

  phase5::PhaseBreakerParams phaseBreakerParams;
  phase5::AntiCorrelationParams antiCorrelationParams;
  phase5::ContrastRemapParams contrastRemapParams;
  phase5::SalienceScramblerParams salienceScramblerParams;
  phase5::NullModelParams nullModelParams;

  // Preset base frequency/amplitude. These override the global engine
  // oscillator values while therapy routing is active.
  float baseFreq = 6200.0f;
  float baseAmp = 0.2f;

  float therapyIntensity = 0.5f;

  // RMP
  float rmpDepth = 0.1f;
  float rmpRate = 5.0f;

  // PIP
  float pipInterval = 0.2f;  // 200 ms
  float pipDuration = 0.02f; // 20 ms

  // Sidebands
  float sidebandOffset = 100.0f;
  float sidebandIntensity = 0.33f;

  // Binaural
  float binauralOffset = 5.0f;

  /// Silent, all-modules-off config for session teardown (avoids default intensity
  /// snapping back to 0.5 and causing a stop click).
  static TherapyConfig inactive() {
    TherapyConfig c;
    c.therapyIntensity = 0.0f;
    c.baseAmp = 0.0f;
    return c;
  }
};
