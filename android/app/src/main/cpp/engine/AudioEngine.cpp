#include "AudioEngine.h" // Includes the declaration of the AudioEngine class.
#include <algorithm>

namespace {
constexpr float kAmplitudeSmoothingMs = 8.0f;
constexpr float kTransportRampMs = 20.0f;
}

AudioEngine::~AudioEngine() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (stream_) {
    stream_->requestStop();
    stream_->close();
    stream_.reset();
  }
}

/// @brief Starts the Oboe audio stream.
///
/// This method attempts to create and start an audio stream with specific
/// properties suitable for low-latency audio output.
/// It uses a mutex to ensure thread-safe access to the stream.
///
/// @return True if the stream is successfully opened and started, false otherwise.
bool AudioEngine::start() {
  std::lock_guard<std::mutex> lock(mutex_); // Acquire a lock to protect shared resources.
  if (stream_) {
    // Keep stream alive and treat start/stop as transport fades to avoid HAL stop/start pops.
    amplitudeSmoother_.setTarget(amplitudeTarget_.load(std::memory_order_relaxed));
    transportSmoother_.setTarget(1.0f);
    return true;
  }

  // Create an AudioStreamBuilder to configure the audio stream.
  oboe::AudioStreamBuilder builder;
  builder.setDirection(oboe::Direction::Output) // Set stream direction to output.
      ->setPerformanceMode(oboe::PerformanceMode::LowLatency) // Prioritize low latency.
      ->setSharingMode(oboe::SharingMode::Exclusive) // Request exclusive access to the audio device.
      ->setFormat(oboe::AudioFormat::Float) // Use float samples.
      ->setChannelCount(1) // Mono audio.
      ->setSampleRate(48000) // Set sample rate to 48000 Hz.
      ->setDataCallback(this); // Set this class as the data callback handler.

  // Attempt to open the audio stream.
  if (builder.openStream(stream_) != oboe::Result::OK) {
    // If opening the stream fails, log an error and return false.
    // (Error logging not shown in this snippet but would typically be here).
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

  // Request the stream to start.
  if (stream_->requestStart() != oboe::Result::OK) {
    stream_->close();
    stream_.reset();
    return false;
  }
  return true;
}

/// @brief Fades audio output to silence without tearing down the stream.
///
/// Keeping the stream alive avoids device-dependent pops caused by hardware
/// route reconfiguration during stop/close.
void AudioEngine::stop() {
  std::lock_guard<std::mutex> lock(mutex_); // Acquire a lock.
  if (stream_) { // Check if a stream exists.
    transportSmoother_.setTarget(0.0f);
  }
}

/// @brief Delegates the frequency setting to the internal Oscillator.
/// @param hz The desired frequency in Hertz.
void AudioEngine::setFrequency(float hz) {
  osc_.setFrequency(hz);
}

/// @brief Sets the amplitude for the audio output.
///
/// Uses an atomic store operation for thread-safe updates to the amplitude.
///
/// @param amp The desired amplitude value (e.g., 0.0 to 1.0).
void AudioEngine::setAmplitude(float amp) {
  const float clampedAmp = std::clamp(amp, 0.0f, 1.0f);
  amplitudeTarget_.store(clampedAmp, std::memory_order_relaxed);
  amplitudeSmoother_.setTarget(clampedAmp);
}

/// @brief Oboe audio data callback.
///
/// This method is called by Oboe when the audio stream requires more data.
/// It generates audio samples by processing the internal oscillator and
/// mixes them with the current amplitude before writing to the output buffer.
///
/// @param audioStream Pointer to the Oboe audio stream.
/// @param audioData Pointer to the buffer where audio samples are written.
/// @param numFrames The number of frames (sets of samples) to render.
/// @return `oboe::DataCallbackResult::Continue` to keep the stream running.
oboe::DataCallbackResult AudioEngine::onAudioReady(
    oboe::AudioStream*, void* audioData, int32_t numFrames) {

  // Cast the void pointer to a float pointer for audio data.
  float* out = static_cast<float*>(audioData);

  // Generate audio samples for each frame.
  for (int i = 0; i < numFrames; ++i) {
    const float transport = transportSmoother_.process();
    const float amp = amplitudeSmoother_.process();
    // Multiply the oscillator's output by the current amplitude and store it in the buffer.
    out[i] = transport * amp * osc_.process();
  }
  return oboe::DataCallbackResult::Continue; // Indicate that the stream should continue.
}
