#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef void* NativeAudioHandle;

NativeAudioHandle audio_create();
void audio_destroy(NativeAudioHandle);
int audio_start(NativeAudioHandle);
void audio_stop(NativeAudioHandle);
void audio_set_frequency(NativeAudioHandle, float);
void audio_set_amplitude(NativeAudioHandle, float);

#ifdef __cplusplus
}
#endif
