#include "VoiceManager.h"

#include <algorithm>

VoiceManager::VoiceManager() {
  setActiveVoiceCount(1);
}

void VoiceManager::setActiveVoiceCount(uint32_t count) {
  const uint32_t clamped = std::clamp(count, 1u, kMaxVoices);
  activeVoiceCount_.store(clamped, std::memory_order_relaxed);
}

uint32_t VoiceManager::activeVoiceCount() const {
  return activeVoiceCount_.load(std::memory_order_relaxed);
}

void VoiceManager::setFrequency(float hz) {
  for (auto& voice : voices_) {
    voice.setFrequency(hz);
  }
}

void VoiceManager::setTargetFrequency(double hz) {
  for (auto& voice : voices_) {
    voice.setTargetFrequency(hz);
  }
}

void VoiceManager::resetPhases() {
  const uint32_t count = activeVoiceCount();
  for (uint32_t i = 0; i < count; ++i) {
    voices_[i].resetPhase();
  }
}

float VoiceManager::process() {
  const uint32_t count = activeVoiceCount();
  double sum = 0.0;
  for (uint32_t i = 0; i < count; ++i) {
    sum += static_cast<double>(voices_[i].process());
  }
  return static_cast<float>(sum / static_cast<double>(count));
}

