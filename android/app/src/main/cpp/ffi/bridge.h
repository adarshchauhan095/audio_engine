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

int audio_therapy_start(NativeAudioHandle handle, int subthreshold, int rmp,
                        int pip, int sidebands, int binaural, float intensity,
                        float baseFreq, float baseAmp, float rmpDepth,
                        float rmpRate, float pipInterval, float pipDuration,
                        float sidebandOffset, float sidebandIntensity,
                        float binauralOffset);

int audio_therapy_update(NativeAudioHandle handle, int subthreshold, int rmp,
                         int pip, int sidebands, int binaural, float intensity,
                         float baseFreq, float baseAmp, float rmpDepth,
                         float rmpRate, float pipInterval, float pipDuration,
                         float sidebandOffset, float sidebandIntensity,
                         float binauralOffset);

int audio_therapy_stop(NativeAudioHandle handle);

// Phase 2 (AM/FM/NBN + filters) - independent API surface.
int audio_phase2_start(NativeAudioHandle handle, int modulationType, int filterType,
                       float intensity, float baseFreq, float baseAmp,
                       float depth, float rateHz, float bandwidthHz,
                       float filterFreqHz, float q, float transitionMs);

int audio_phase2_update(NativeAudioHandle handle, int modulationType, int filterType,
                        float intensity, float baseFreq, float baseAmp,
                        float depth, float rateHz, float bandwidthHz,
                        float filterFreqHz, float q, float transitionMs);

int audio_phase2_stop(NativeAudioHandle handle);

void audio_set_stereo_enabled(NativeAudioHandle handle, int enabled);

void audio_register_log_callback(NativeAudioHandle handle, AudioLogCallback cb);

typedef void (*AudioOutputLostCallback)(void);

void audio_register_output_lost_callback(NativeAudioHandle handle,
                                         AudioOutputLostCallback cb);

void audio_reset_output_stream(NativeAudioHandle handle);

void audio_set_output_device_id(NativeAudioHandle handle, int deviceId);

// Phase 5.2 testing hooks
int audio_phase52_run_test(NativeAudioHandle handle, int testId);

void audio_phase52_set_generator_params(NativeAudioHandle h, int generatorId, float p1, float p2, float p3, float p4, float p5);
void audio_phase52_get_diagnostics(NativeAudioHandle h, float* outRms, float* outPeak, int* outNanCount, int* outClipCount);

/// Closes the extern "C" block.
#ifdef __cplusplus
}
#endif
