#pragma once

struct TherapyConfig {
  bool enableSubthreshold = false;
  bool enableRMP = false;
  bool enablePIP = false;
  bool enableSidebands = false;
  bool enableBinaural = false;

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
};
