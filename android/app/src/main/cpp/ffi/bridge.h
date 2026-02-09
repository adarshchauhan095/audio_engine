#pragma once // Ensures this header file is included only once during compilation.

/// Guards the C-style function declarations to ensure they are compiled correctly
/// when included in a C++ file. This allows C++ code to call C functions.
#ifdef __cplusplus
extern "C" {
#endif

/// @typedef NativeAudioHandle
/// @brief An opaque pointer type used to represent a handle to the native audio engine instance.
///
/// This type is used to pass references to the native AudioEngine object between
/// Dart/Flutter (via FFI) and the native C++ code without exposing the internal
/// C++ class structure to Dart.
typedef void* NativeAudioHandle;

/// @brief Creates and initializes a new instance of the native audio engine.
/// @return A handle to the newly created native audio engine instance.
NativeAudioHandle audio_create();

/// @brief Destroys and cleans up a native audio engine instance.
/// @param handle A handle to the native audio engine instance to be destroyed.
void audio_destroy(NativeAudioHandle handle);

/// @brief Starts audio playback for the specified native audio engine.
/// @param handle A handle to the native audio engine instance.
/// @return 1 if audio started successfully, 0 otherwise.
int audio_start(NativeAudioHandle handle);

/// @brief Stops audio playback for the specified native audio engine.
/// @param handle A handle to the native audio engine instance.
void audio_stop(NativeAudioHandle handle);

/// @brief Sets the frequency of the audio oscillator for the given native audio engine.
/// @param handle A handle to the native audio engine instance.
/// @param frequency The desired frequency in Hertz (float).
void audio_set_frequency(NativeAudioHandle handle, float frequency);

/// @brief Sets the amplitude (volume) of the audio output for the given native audio engine.
/// @param handle A handle to the native audio engine instance.
/// @param amplitude The desired amplitude, typically between 0.0 and 1.0 (float).
void audio_set_amplitude(NativeAudioHandle handle, float amplitude);

/// Closes the extern "C" block.
#ifdef __cplusplus
}
#endif
