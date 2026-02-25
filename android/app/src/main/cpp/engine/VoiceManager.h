#pragma once

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>

#include "Oscillator.h"

/// Owns a small fixed set of oscillators and renders active voices.
///
/// Default configuration keeps one voice active, matching previous behavior.
/// Multi-voice support is optional and only used when explicitly enabled.
class VoiceManager {
public:
  static constexpr uint32_t kMaxVoices = 8;

  VoiceManager();

  void setActiveVoiceCount(uint32_t count);
  uint32_t activeVoiceCount() const;

  void setFrequency(float hz);
  void setTargetFrequency(double hz);

  float process();

private:
  std::array<Oscillator, kMaxVoices> voices_;
  std::atomic<uint32_t> activeVoiceCount_{1};
};

