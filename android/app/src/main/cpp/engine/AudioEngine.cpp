#include "AudioEngine.h"

#include <algorithm>

namespace {
constexpr float kAmplitudeSmoothingMs = 8.0f;
constexpr float kTransportRampMs = 20.0f;
}  // namespace

AudioEngine::~AudioEngine() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (stream_) {
    stream_->requestStop();
    stream_->close();
    stream_.reset();
  }
}

bool AudioEngine::start() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (stream_) {
    amplitudeSmoother_.setTarget(amplitudeTarget_.load(std::memory_order_relaxed));
    transportSmoother_.setTarget(1.0f);
    running_.store(true, std::memory_order_relaxed);
    return true;
  }

  oboe::AudioStreamBuilder builder;
  builder.setDirection(oboe::Direction::Output)
      ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
      ->setSharingMode(oboe::SharingMode::Exclusive)
      ->setFormat(oboe::AudioFormat::Float)
      ->setChannelCount(1)
      ->setSampleRate(48000)
      ->setDataCallback(this);

  if (builder.openStream(stream_) != oboe::Result::OK) {
    return false;
  }

  const float currentAmplitude = amplitudeTarget_.load(std::memory_order_relaxed);
  amplitudeSmoother_.setSmoothingTimeMs(
      kAmplitudeSmoothingMs,
      static_cast<float>(stream_->getSampleRate()));
  amplitudeSmoother_.reset(currentAmplitude);

  transportSmoother_.setSmoothingTimeMs(
      kTransportRampMs,
      static_cast<float>(stream_->getSampleRate()));
  transportSmoother_.reset(0.0f);
  transportSmoother_.setTarget(1.0f);

  if (stream_->requestStart() != oboe::Result::OK) {
    stream_->close();
    stream_.reset();
    return false;
  }

  running_.store(true, std::memory_order_relaxed);
  return true;
}

void AudioEngine::stop() {
  std::lock_guard<std::mutex> lock(mutex_);
  running_.store(false, std::memory_order_relaxed);
  if (stream_) {
    transportSmoother_.setTarget(0.0f);
  }
}

bool AudioEngine::isRunning() const {
  return running_.load(std::memory_order_relaxed);
}

void AudioEngine::setFrequency(float hz) {
  voiceManager_.setFrequency(hz);
}

void AudioEngine::setTargetFrequency(double hz) {
  voiceManager_.setTargetFrequency(hz);
}

void AudioEngine::setAmplitude(float amp) {
  const float clampedAmp = std::clamp(amp, 0.0f, 1.0f);
  amplitudeTarget_.store(clampedAmp, std::memory_order_relaxed);
  amplitudeSmoother_.setTarget(clampedAmp);
}

void AudioEngine::scheduleSequence() {
  eventScheduler_.scheduleDefaultSequence();
}

void AudioEngine::startSession() {
  eventScheduler_.startSession();
}

void AudioEngine::stopSession() {
  eventScheduler_.stopSession();
}

oboe::DataCallbackResult AudioEngine::onAudioReady(
    oboe::AudioStream*,
    void* audioData,
    int32_t numFrames) {
  float* out = static_cast<float*>(audioData);
  for (int32_t i = 0; i < numFrames; ++i) {
    const float transport = transportSmoother_.process();
    const float amp = amplitudeSmoother_.process();
    out[i] = transport * amp * voiceManager_.process();
  }
  return oboe::DataCallbackResult::Continue;
}

