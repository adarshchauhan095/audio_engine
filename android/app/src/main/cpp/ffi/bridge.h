#pragma once

/// C ABI for Dart FFI. Thin wrappers around the native [AudioEngine];
/// no DSP or parameter logic—all calls delegate to AudioEngine methods.
#ifdef __cplusplus
extern "C" {
#endif

/// @typedef NativeAudioHandle
/// @brief An opaque pointer type used to represent a handle to the native audio
/// engine instance.
///
/// This type is used to pass references to the native AudioEngine object
/// between Dart/Flutter (via FFI) and the native C++ code without exposing the
/// internal C++ class structure to Dart.
typedef void *NativeAudioHandle;

/// @brief Creates and initializes a new instance of the native audio engine.
/// @return A handle to the newly created native audio engine instance.
NativeAudioHandle audio_create();

/// @brief Destroys and cleans up a native audio engine instance.
/// @param handle A handle to the native audio engine instance to be destroyed.
void audio_destroy(NativeAudioHandle handle);

/// @brief Starts audio playback for the specified native audio engine.
/// @param handle A handle to the native audio engine instance.
/// @return 0 if audio started successfully, non-zero otherwise.
int audio_start(NativeAudioHandle handle);

/// @brief Stops audio playback for the specified native audio engine.
/// @param handle A handle to the native audio engine instance.
void audio_stop(NativeAudioHandle handle);

/// @brief Returns whether the engine is currently running (transport active).
/// @param handle A handle to the native audio engine instance.
/// @return 1 if running, 0 if stopped or fading out.
int audio_is_running(NativeAudioHandle handle);

/// @brief Sets the frequency of the audio oscillator for the given native audio
/// engine.
/// @param handle A handle to the native audio engine instance.
/// @param frequency The desired frequency in Hertz (float).
void audio_set_frequency(NativeAudioHandle handle, float frequency);

/// @brief Sets the high-precision target frequency for the oscillator layer.
/// @param handle A handle to the native audio engine instance.
/// @param frequency The desired frequency in Hertz (double).
void audio_set_target_frequency(NativeAudioHandle handle, double frequency);

/// @brief Sets the amplitude (volume) of the audio output for the given native
/// audio engine.
/// @param handle A handle to the native audio engine instance.
/// @param amplitude The desired amplitude, typically between 0.0 and 1.0
/// (float).
void audio_set_amplitude(NativeAudioHandle handle, float amplitude);

/// @brief Schedules a default sequence payload for future session playback.
/// @param handle A handle to the native audio engine instance.
void audio_schedule_sequence(NativeAudioHandle handle);

/// @brief Starts a session context for scheduler-owned events.
/// @param handle A handle to the native audio engine instance.
void audio_start_session(NativeAudioHandle handle);

/// @brief Stops the active session context.
/// @param handle A handle to the native audio engine instance.
void audio_stop_session(NativeAudioHandle handle);

typedef void (*AudioLogCallback)(const char *msg);

void audio_therapy_start(NativeAudioHandle handle, int subthreshold, int rmp,
                         int pip, int sidebands, int binaural, float intensity,
                         float baseFreq, float baseAmp, float rmpDepth,
                         float rmpRate, float pipInterval, float pipDuration,
                         float sidebandOffset, float sidebandIntensity,
                         float binauralOffset);

void audio_therapy_update(NativeAudioHandle handle, int subthreshold, int rmp,
                          int pip, int sidebands, int binaural, float intensity,
                          float baseFreq, float baseAmp, float rmpDepth,
                          float rmpRate, float pipInterval, float pipDuration,
                          float sidebandOffset, float sidebandIntensity,
                          float binauralOffset);

void audio_therapy_stop(NativeAudioHandle handle);

void audio_set_stereo_enabled(NativeAudioHandle handle, int enabled);

void audio_register_log_callback(NativeAudioHandle handle, AudioLogCallback cb);

/// Closes the extern "C" block.
#ifdef __cplusplus
}
#endif
