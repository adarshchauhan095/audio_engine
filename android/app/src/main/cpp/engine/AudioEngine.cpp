#include "AudioEngine.h"

bool AudioEngine::start() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (stream_) return true;

  oboe::AudioStreamBuilder builder;
  builder.setDirection(oboe::Direction::Output)
      ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
      ->setSharingMode(oboe::SharingMode::Exclusive)
      ->setFormat(oboe::AudioFormat::Float)
      ->setChannelCount(1)
      ->setSampleRate(48000)
      ->setDataCallback(this);

  if (builder.openStream(stream_) != oboe::Result::OK) return false;
  return stream_->requestStart() == oboe::Result::OK;
}

void AudioEngine::stop() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (stream_) {
    stream_->requestStop();
    stream_->close();
    stream_.reset();
  }
}

void AudioEngine::setFrequency(float hz) {
  osc_.setFrequency(hz);
}

void AudioEngine::setAmplitude(float amp) {
  amplitude_.store(amp, std::memory_order_relaxed);
}

oboe::DataCallbackResult AudioEngine::onAudioReady(
    oboe::AudioStream*, void* audioData, int32_t numFrames) {

  float* out = static_cast<float*>(audioData);
  float amp = amplitude_.load(std::memory_order_relaxed);

  for (int i = 0; i < numFrames; ++i) {
    out[i] = amp * osc_.process();
  }
  return oboe::DataCallbackResult::Continue;
}
