#pragma once
#include <oboe/Oboe.h>
#include <memory>
#include <mutex>
#include "Oscillator.h"

class AudioEngine : public oboe::AudioStreamDataCallback {
public:
  bool start();
  void stop();

  void setFrequency(float hz);
  void setAmplitude(float amp);

  oboe::DataCallbackResult onAudioReady(
    oboe::AudioStream*,
    void* audioData,
    int32_t numFrames
  ) override;

private:
  std::mutex mutex_;
  std::shared_ptr<oboe::AudioStream> stream_;
  Oscillator osc_;
  std::atomic<float> amplitude_{0.3f};
};
