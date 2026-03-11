#include "AudioEngine.h"
#include "TherapyConfig.h"

#include <algorithm>

namespace {
constexpr float kAmplitudeSmoothingMs = 8.0f;
constexpr float kTransportRampMs = 20.0f;
} // namespace

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
    amplitudeSmoother_.setTarget(
        amplitudeTarget_.load(std::memory_order_relaxed));
    transportSmoother_.setTarget(1.0f);
    running_.store(true, std::memory_order_relaxed);
    return true;
  }

  oboe::AudioStreamBuilder builder;
  builder.setDirection(oboe::Direction::Output)
      ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
      ->setSharingMode(oboe::SharingMode::Exclusive)
      ->setFormat(oboe::AudioFormat::Float)
      ->setChannelCount(2)
      ->setSampleRate(48000)
      ->setDataCallback(this);

  if (builder.openStream(stream_) != oboe::Result::OK) {
    return false;
  }

  const float currentAmplitude =
      amplitudeTarget_.load(std::memory_order_relaxed);
  amplitudeSmoother_.setSmoothingTimeMs(
      kAmplitudeSmoothingMs, static_cast<float>(stream_->getSampleRate()));
  amplitudeSmoother_.reset(currentAmplitude);

  transportSmoother_.setSmoothingTimeMs(
      kTransportRampMs, static_cast<float>(stream_->getSampleRate()));
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
  currentFreq_.store(hz, std::memory_order_relaxed);
  voiceManager_.setFrequency(hz);
}

void AudioEngine::setTargetFrequency(double hz) {
  currentFreq_.store(hz, std::memory_order_relaxed);
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

void AudioEngine::startSession() { eventScheduler_.startSession(); }

void AudioEngine::stopSession() { eventScheduler_.stopSession(); }

void AudioEngine::setStereoEnabled(bool enabled) {
  stereoEnabled_.store(enabled, std::memory_order_relaxed);
}

int AudioEngine::therapyStart(const TherapyConfig &config) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!stream_) {
    // init therapy router if needed
    therapyRouter_.init(48000.0);
  } else {
    therapyRouter_.init(stream_->getSampleRate());
  }
  therapyRouter_.updateConfig(config);
  log("Therapy started");
  return 1;
}

int AudioEngine::therapyUpdate(const TherapyConfig &config) {
  std::lock_guard<std::mutex> lock(mutex_);
  therapyRouter_.updateConfig(config);
  log("Therapy updated");
  return 1;
}

int AudioEngine::therapyStop() {
  std::lock_guard<std::mutex> lock(mutex_);
  TherapyConfig emptyConfig;
  therapyRouter_.updateConfig(emptyConfig);
  log("Therapy stopped");
  return 1;
}

oboe::DataCallbackResult AudioEngine::onAudioReady(oboe::AudioStream *,
                                                   void *audioData,
                                                   int32_t numFrames) {
  float *out = static_cast<float *>(audioData);
  double freq = currentFreq_.load(std::memory_order_relaxed);
  bool isStereo = stereoEnabled_.load(std::memory_order_relaxed);

  for (int32_t i = 0; i < numFrames; ++i) {
    const float transport = transportSmoother_.process();
    const float amp = amplitudeSmoother_.process();

    if (therapyRouter_.isActive()) {
      StereoSample sr = therapyRouter_.process(freq, amp);
      if (!isStereo) {
        float mono = (sr.left + sr.right) * 0.5f;
        sr.left = mono;
        sr.right = mono;
      }
      out[i * 2] = sr.left * transport;
      out[i * 2 + 1] = sr.right * transport;
      // Keep voice manager processing silent to avoid it falling behind
      voiceManager_.process();
    } else {
      float mono = transport * amp * voiceManager_.process();
      out[i * 2] = mono;
      out[i * 2 + 1] = mono;
    }
  }
  return oboe::DataCallbackResult::Continue;
}
