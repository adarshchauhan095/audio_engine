#pragma once // Ensures this header file is included only once during compilation.

#include <oboe/Oboe.h>    // Oboe library for high-performance audio.
#include <atomic>
#include <memory>         // For std::shared_ptr.
#include <mutex>          // For std::mutex to protect shared resources.
#include "Oscillator.h"   // Includes the Oscillator class definition.
#include "ParameterSmoother.h"

/// @class AudioEngine
/// @brief Engine core: Oboe stream, start/stop with transport ramp, amplitude and frequency control.
///
/// DSP layer: [Oscillator] and [ParameterSmoother] for amplitude and transport.
/// Parameter updates are sample-accurate (ramps in onAudioReady) and thread-safe
/// (atomic targets from UI). Exposes start, stop, setFrequency, setAmplitude, isRunning.
class AudioEngine : public oboe::AudioStreamDataCallback {
public:
  ~AudioEngine();

  /// @brief Starts the audio stream (with smooth fade-in).
  /// @return True if the stream starts successfully, false otherwise.
  bool start();

  /// @brief Fades output to silence while keeping the stream alive (no HAL stop pops).
  void stop();

  /// @brief Returns true if transport is active (running), false if stopped or fading out.
  bool isRunning() const;

  /// @brief Sets the frequency of the audio oscillator (smoothed in Oscillator).
  /// @param hz The desired frequency in Hertz.
  void setFrequency(float hz);

  /// @brief Sets the amplitude (volume) of the audio output (ramp-smoothed).
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
  ParameterSmoother amplitudeSmoother_;              ///< Smooths amplitude changes to avoid zipper noise and clicks.
  ParameterSmoother transportSmoother_;              ///< Handles short start/stop gain ramps.
  std::atomic<float> amplitudeTarget_{0.3f};         ///< User-set amplitude target preserved across start/stop.
  std::atomic<bool> running_{false};                  ///< Engine state: true when transport is active (start called, stop not yet).
};
