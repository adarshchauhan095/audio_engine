#include "bridge.h"                // Includes the FFI bridge declarations.
#include "../engine/AudioEngine.h" // Includes the C++ AudioEngine class definition.
#include "../engine/TherapyConfig.h"
#include "../engine/advance_engine/AdvanceEngineConfig.h"
#include "../engine/tests/GeneratorTests.h"

/// @brief Implements `audio_create()` from `bridge.h`.
/// Creates a new instance of the `AudioEngine` class on the heap and returns
/// a `NativeAudioHandle` (void pointer) to it.
/// The caller is responsible for eventually calling `audio_destroy` to free
/// this memory.
NativeAudioHandle audio_create() { return new AudioEngine(); }

/// @brief Implements `audio_destroy()` from `bridge.h`.
/// Deletes the `AudioEngine` instance pointed to by the given handle,
/// freeing its allocated memory.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance to be
/// destroyed.
void audio_destroy(NativeAudioHandle h) {
  delete static_cast<AudioEngine *>(
      h); // Casts the handle back to an AudioEngine pointer and deletes it.
}

/// @brief Implements `audio_start()` from `bridge.h`.
/// Calls the `start()` method on the `AudioEngine` instance.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @return 0 if the audio started successfully, -1 otherwise.
int audio_start(NativeAudioHandle h) {
  // Casts the handle to AudioEngine* and calls its start() method.
  // Returns 0 for success (true), -1 for failure (false).
  return static_cast<AudioEngine *>(h)->start() ? 0 : -1;
}

/// @brief Implements `audio_stop()` from `bridge.h`.
/// Calls the `stop()` method on the `AudioEngine` instance.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
void audio_stop(NativeAudioHandle h) { static_cast<AudioEngine *>(h)->stop(); }

/// @brief Implements `audio_is_running()` from `bridge.h`.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @return 1 if running, 0 otherwise.
int audio_is_running(NativeAudioHandle h) {
  return static_cast<AudioEngine *>(h)->isRunning() ? 1 : 0;
}

/// @brief Implements `audio_set_frequency()` from `bridge.h`.
/// Calls the `setFrequency()` method on the `AudioEngine` instance's
/// oscillator.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @param hz The desired frequency in Hertz.
void audio_set_frequency(NativeAudioHandle h, float hz) {
  static_cast<AudioEngine *>(h)->setFrequency(
      hz); // Casts and calls setFrequency().
}

/// @brief Implements `audio_set_target_frequency()` from `bridge.h`.
/// Calls the high-precision frequency target setter.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @param hz The desired target frequency in Hertz.
void audio_set_target_frequency(NativeAudioHandle h, double hz) {
  static_cast<AudioEngine *>(h)->setTargetFrequency(hz);
}

/// @brief Implements `audio_set_amplitude()` from `bridge.h`.
/// Calls the `setAmplitude()` method on the `AudioEngine` instance.
/// @param h The `NativeAudioHandle` to the `AudioEngine` instance.
/// @param a The desired amplitude.
void audio_set_amplitude(NativeAudioHandle h, float a) {
  static_cast<AudioEngine *>(h)->setAmplitude(
      a); // Casts and calls setAmplitude().
}

/// @brief Implements `audio_schedule_sequence()` from `bridge.h`.
void audio_schedule_sequence(NativeAudioHandle h) {
  static_cast<AudioEngine *>(h)->scheduleSequence();
}

/// @brief Implements `audio_start_session()` from `bridge.h`.
void audio_start_session(NativeAudioHandle h) {
  static_cast<AudioEngine *>(h)->startSession();
}

/// @brief Implements `audio_stop_session()` from `bridge.h`.
void audio_stop_session(NativeAudioHandle h) {
  static_cast<AudioEngine *>(h)->stopSession();
}

static TherapyConfig createConfig(int subthreshold, int rmp, int pip,
                                  int sidebands, int binaural, float intensity,
                                  float baseFreq, float baseAmp, float rmpDepth,
                                  float rmpRate, float pipInterval,
                                  float pipDuration, float sidebandOffset,
                                  float sidebandIntensity,
                                  float binauralOffset) {

  TherapyConfig c;
  c.enableSubthreshold = subthreshold != 0;
  c.enableRMP = rmp != 0;
  c.enablePIP = pip != 0;
  c.enableSidebands = sidebands != 0;
  c.enableBinaural = binaural != 0;
  c.baseFreq = baseFreq;
  c.baseAmp = baseAmp;
  c.therapyIntensity = intensity;

  c.rmpDepth = rmpDepth;
  c.rmpRate = rmpRate;
  c.pipInterval = pipInterval;
  c.pipDuration = pipDuration;
  c.sidebandOffset = sidebandOffset;
  c.sidebandIntensity = sidebandIntensity;
  c.binauralOffset = binauralOffset;

  return c;
}

int audio_therapy_start(NativeAudioHandle h, int subthreshold, int rmp, int pip,
                        int sidebands, int binaural, float intensity,
                        float baseFreq, float baseAmp, float rmpDepth,
                        float rmpRate, float pipInterval, float pipDuration,
                        float sidebandOffset, float sidebandIntensity,
                        float binauralOffset) {

  return static_cast<AudioEngine *>(h)->therapyStart(createConfig(
      subthreshold, rmp, pip, sidebands, binaural, intensity, baseFreq, baseAmp,
      rmpDepth, rmpRate, pipInterval, pipDuration, sidebandOffset,
      sidebandIntensity, binauralOffset));
}

int audio_therapy_update(NativeAudioHandle h, int subthreshold, int rmp,
                         int pip, int sidebands, int binaural, float intensity,
                         float baseFreq, float baseAmp, float rmpDepth,
                         float rmpRate, float pipInterval, float pipDuration,
                         float sidebandOffset, float sidebandIntensity,
                         float binauralOffset) {

  return static_cast<AudioEngine *>(h)->therapyUpdate(createConfig(
      subthreshold, rmp, pip, sidebands, binaural, intensity, baseFreq, baseAmp,
      rmpDepth, rmpRate, pipInterval, pipDuration, sidebandOffset,
      sidebandIntensity, binauralOffset));
}

int audio_therapy_stop(NativeAudioHandle h) {
  return static_cast<AudioEngine *>(h)->therapyStop();
}

static Phase2Config createPhase2Config(int modulationType, int filterType,
                                       float intensity, float baseFreq,
                                       float baseAmp, float depth, float rateHz,
                                       float bandwidthHz, float filterFreqHz,
                                       float q, float transitionMs) {
  Phase2Config c;
  c.enabled = true;
  c.modulation =
      static_cast<Phase2Config::ModulationType>(modulationType);
  c.filter = static_cast<Phase2Config::FilterType>(filterType);
  c.intensity = intensity;
  c.baseFreq = baseFreq;
  c.baseAmp = baseAmp;
  c.depth = depth;
  c.rateHz = rateHz;
  c.bandwidthHz = bandwidthHz;
  c.cutoffHz = filterFreqHz;
  c.q = q;
  c.transitionMs = transitionMs;
  return c;
}

int audio_phase2_start(NativeAudioHandle h, int modulationType, int filterType,
                       float intensity, float baseFreq, float baseAmp,
                       float depth, float rateHz, float bandwidthHz,
                       float filterFreqHz, float q, float transitionMs) {
  return static_cast<AudioEngine*>(h)->phase2Start(createPhase2Config(
      modulationType, filterType, intensity, baseFreq, baseAmp, depth, rateHz,
      bandwidthHz, filterFreqHz, q, transitionMs));
}

int audio_phase2_update(NativeAudioHandle h, int modulationType, int filterType,
                        float intensity, float baseFreq, float baseAmp,
                        float depth, float rateHz, float bandwidthHz,
                        float filterFreqHz, float q, float transitionMs) {
  return static_cast<AudioEngine*>(h)->phase2Update(createPhase2Config(
      modulationType, filterType, intensity, baseFreq, baseAmp, depth, rateHz,
      bandwidthHz, filterFreqHz, q, transitionMs));
}

int audio_phase2_stop(NativeAudioHandle h) {
  return static_cast<AudioEngine*>(h)->phase2Stop();
}

void audio_set_stereo_enabled(NativeAudioHandle h, int enabled) {
  static_cast<AudioEngine *>(h)->setStereoEnabled(enabled != 0);
}

static AudioLogCallback g_logCb = nullptr;

void audio_register_log_callback(NativeAudioHandle h, AudioLogCallback cb) {
  g_logCb = cb;
  static_cast<AudioEngine *>(h)->setLogCallback(cb);
}

void audio_register_output_lost_callback(NativeAudioHandle h,
                                         AudioOutputLostCallback cb) {
  static_cast<AudioEngine *>(h)->setOutputLostCallback(cb);
}

void audio_reset_output_stream(NativeAudioHandle h) {
  static_cast<AudioEngine *>(h)->resetOutputStream();
}

void audio_set_output_device_id(NativeAudioHandle h, int deviceId) {
  static_cast<AudioEngine *>(h)->setPreferredOutputDeviceId(
      static_cast<int32_t>(deviceId));
}

int audio_phase52_run_test(NativeAudioHandle handle, int testId) {
  if (!handle) return -1;
  // testId mapping:
  // 1 = Run all standard Generator tests (PhaseBreaker, etc.)
  // We can just invoke GeneratorTests::runAll() directly since it outputs
  // via TestUtils::printResult, but we need those results routed to logCallback.
  // Actually, TestUtils currently uses std::cout/cerr. We should update TestUtils 
  // to use Logging::info / Logging::error instead so it routes via the FFI log callback!
  
  if (testId == 1) {
    phase5::tests::GeneratorTests::runAll([](const char* msg) {
        if (g_logCb) g_logCb(msg);
    });
    return 0;
  }
  return 1;
}

void audio_phase52_set_generator_params(NativeAudioHandle handle, int generatorId, float p1, float p2, float p3, float p4, float p5) {
  if (handle == nullptr) return;
  auto* engine = reinterpret_cast<AudioEngine*>(handle);
  engine->setPhase52GeneratorParams(generatorId, p1, p2, p3, p4, p5);
}

void audio_phase52_get_diagnostics(NativeAudioHandle handle, float* outRms, float* outPeak, int* outNanCount, int* outClipCount) {
  if (handle == nullptr) {
      if (outRms) *outRms = 0;
      if (outPeak) *outPeak = 0;
      if (outNanCount) *outNanCount = 0;
      if (outClipCount) *outClipCount = 0;
      return;
  }
  auto* engine = reinterpret_cast<AudioEngine*>(handle);
  engine->getDiagnostics(outRms, outPeak, outNanCount, outClipCount);
}
