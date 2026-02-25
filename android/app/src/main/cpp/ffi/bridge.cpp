#include "bridge.h"          // Includes the FFI bridge declarations.
#include "../engine/AudioEngine.h" // Includes the C++ AudioEngine class definition.

/// @brief Implements `audio_create()` from `bridge.h`.
/// Creates a new instance of the `AudioEngine` class on the heap and returns
/// a `NativeAudioHandle` (void pointer) to it.
/// The caller is responsible for eventually calling `audio_destroy` to free this memory.
NativeAudioHandle audio_create() {
  return new AudioEngine();
}

/// @brief Implements `audio_destroy()` from `bridge.h`.
/// Deletes the `AudioEngine` instance pointed to by the given handle,
/// freeing its allocated memory.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance to be destroyed.
void audio_destroy(NativeAudioHandle h) {
  delete static_cast<AudioEngine*>(h); // Casts the handle back to an AudioEngine pointer and deletes it.
}

/// @brief Implements `audio_start()` from `bridge.h`.
/// Calls the `start()` method on the `AudioEngine` instance.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @return 0 if the audio started successfully, -1 otherwise.
int audio_start(NativeAudioHandle h) {
  // Casts the handle to AudioEngine* and calls its start() method.
  // Returns 0 for success (true), -1 for failure (false).
  return static_cast<AudioEngine*>(h)->start() ? 0 : -1;
}

/// @brief Implements `audio_stop()` from `bridge.h`.
/// Calls the `stop()` method on the `AudioEngine` instance.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
void audio_stop(NativeAudioHandle h) {
  static_cast<AudioEngine*>(h)->stop();
}

/// @brief Implements `audio_is_running()` from `bridge.h`.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @return 1 if running, 0 otherwise.
int audio_is_running(NativeAudioHandle h) {
  return static_cast<AudioEngine*>(h)->isRunning() ? 1 : 0;
}

/// @brief Implements `audio_set_frequency()` from `bridge.h`.
/// Calls the `setFrequency()` method on the `AudioEngine` instance's oscillator.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @param hz The desired frequency in Hertz.
void audio_set_frequency(NativeAudioHandle h, float hz) {
  static_cast<AudioEngine*>(h)->setFrequency(hz); // Casts and calls setFrequency().
}

/// @brief Implements `audio_set_target_frequency()` from `bridge.h`.
/// Calls the high-precision frequency target setter.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @param hz The desired target frequency in Hertz.
void audio_set_target_frequency(NativeAudioHandle h, double hz) {
  static_cast<AudioEngine*>(h)->setTargetFrequency(hz);
}

/// @brief Implements `audio_set_amplitude()` from `bridge.h`.
/// Calls the `setAmplitude()` method on the `AudioEngine` instance.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @param a The desired amplitude.
void audio_set_amplitude(NativeAudioHandle h, float a) {
  static_cast<AudioEngine*>(h)->setAmplitude(a); // Casts and calls setAmplitude().
}

/// @brief Implements `audio_schedule_sequence()` from `bridge.h`.
void audio_schedule_sequence(NativeAudioHandle h) {
  static_cast<AudioEngine*>(h)->scheduleSequence();
}

/// @brief Implements `audio_start_session()` from `bridge.h`.
void audio_start_session(NativeAudioHandle h) {
  static_cast<AudioEngine*>(h)->startSession();
}

/// @brief Implements `audio_stop_session()` from `bridge.h`.
void audio_stop_session(NativeAudioHandle h) {
  static_cast<AudioEngine*>(h)->stopSession();
}
