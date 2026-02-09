#pragma once // Ensures this header file is included only once during compilation.

#include <oboe/Oboe.h>    // Oboe library for high-performance audio.
#include <memory>         // For std::shared_ptr.
#include <mutex>          // For std::mutex to protect shared resources.
#include "Oscillator.h"   // Includes the Oscillator class definition.

/// @class AudioEngine
/// @brief Manages audio stream creation, playback, and interaction with an oscillator.
///
/// This class extends `oboe::AudioStreamDataCallback` to receive and process
/// audio data. It sets up an Oboe audio stream, controls its lifecycle (start/stop),
/// and allows dynamic adjustment of the audio frequency and amplitude
/// through an internal [Oscillator] instance.
class AudioEngine : public oboe::AudioStreamDataCallback {
public:
  /// @brief Starts the audio stream.
  /// @return True if the stream starts successfully, false otherwise.
  bool start();

  /// @brief Stops the audio stream.
  void stop();

  /// @brief Sets the frequency of the audio oscillator.
  /// @param hz The desired frequency in Hertz.
  void setFrequency(float hz);

  /// @brief Sets the amplitude (volume) of the audio output.
  /// @param amp The desired amplitude, typically between 0.0 (silent) and 1.0 (max volume).
  void setAmplitude(float amp);

  /// @brief Callback method invoked by Oboe when audio data is needed.
  ///
  /// This method generates audio samples from the oscillator, mixes them,
  /// and writes them to the audio buffer.
  ///
  /// @param audioStream A pointer to the Oboe audio stream requesting data.
  /// @param audioData A pointer to the buffer where audio samples should be written.
  /// @param numFrames The number of frames (sets of samples) to be written.
  /// @return `oboe::DataCallbackResult::Continue` to continue playback,
  ///         `oboe::DataCallbackResult::Stop` to stop playback.
  oboe::DataCallbackResult onAudioReady(
    oboe::AudioStream*,
    void* audioData,
    int32_t numFrames
  ) override;

private:
  std::mutex mutex_;                                 ///< Mutex to protect access to shared stream resources.
  std::shared_ptr<oboe::AudioStream> stream_;        ///< Shared pointer to the Oboe audio stream.
  Oscillator osc_;                                   ///< The oscillator instance used to generate audio waveforms.
  std::atomic<float> amplitude_{0.3f};              ///< Atomic float for thread-safe amplitude control, initialized to 0.3.
};
