#include "bridge.h"
#include "../engine/AudioEngine.h"

NativeAudioHandle audio_create() {
  return new AudioEngine();
}

void audio_destroy(NativeAudioHandle h) {
  delete static_cast<AudioEngine*>(h);
}

int audio_start(NativeAudioHandle h) {
  return static_cast<AudioEngine*>(h)->start() ? 0 : -1;
}

void audio_stop(NativeAudioHandle h) {
  static_cast<AudioEngine*>(h)->stop();
}

void audio_set_frequency(NativeAudioHandle h, float hz) {
  static_cast<AudioEngine*>(h)->setFrequency(hz);
}

void audio_set_amplitude(NativeAudioHandle h, float a) {
  static_cast<AudioEngine*>(h)->setAmplitude(a);
}
