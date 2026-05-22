#pragma once

#include <oboe/Oboe.h>

#include <atomic>
#include <memory>
#include <mutex>

#if defined(__ANDROID__)
#include <android/log.h>
#endif

#include "EventScheduler.h"
#include "ParameterSmoother.h"
#include "TherapyRouter.h"
#include "VoiceManager.h"
#include "advance_engine/AdvanceEngineConfig.h"
#include "advance_engine/AdvanceEngineRouter.h"

/// Engine core: Oboe stream + DSP parameter control.
///
/// Existing behavior is preserved for start/stop, amplitude, and
/// frequency updates. New scheduler/session hooks are optional.
class AudioEngine : public oboe::AudioStreamDataCallback,
                    public oboe::AudioStreamErrorCallback {
public:
  ~AudioEngine();

  bool start();
  void stop();
  bool isRunning() const;

  /// Fully closes the output stream (unlike [stop], which keeps the stream
  /// open). Used after Bluetooth/route loss so the next [start] opens on the
  /// current default device.
  void resetOutputStream();

  void setPreferredOutputDeviceId(int32_t deviceId);

  void setFrequency(float hz);
  void setTargetFrequency(double hz);
  void setAmplitude(float amp);

  void scheduleSequence();
  void startSession();
  void stopSession();

  void setStereoEnabled(bool enabled);

  // Therapy API
  int therapyStart(const TherapyConfig &config);
  int therapyUpdate(const TherapyConfig &config);
  int therapyStop();

  // Phase 2 API (AM/FM/NBN + filters) - independent from Therapy API.
  int phase2Start(const Phase2Config &config);
  int phase2Update(const Phase2Config &config);
  int phase2Stop();

  typedef void (*LogCallback)(const char *);
  void setLogCallback(LogCallback cb) { logCb_ = cb; }

  typedef void (*OutputLostCallback)();
  void setOutputLostCallback(OutputLostCallback cb) { outputLostCb_ = cb; }

  oboe::DataCallbackResult onAudioReady(oboe::AudioStream *audioStream,
                                          void *audioData,
                                          int32_t numFrames) override;

  void onErrorBeforeClose(oboe::AudioStream *stream,
                          oboe::Result error) override;

private:
  std::mutex mutex_;
  std::shared_ptr<oboe::AudioStream> stream_;

  VoiceManager voiceManager_;
  EventScheduler eventScheduler_;
  ParameterSmoother amplitudeSmoother_;
  ParameterSmoother transportSmoother_;
  ParameterSmoother therapySessionGainSmoother_;
  TherapyRouter therapyRouter_;
  Phase2Router phase2Router_;

  std::atomic<float> amplitudeTarget_{0.3f};
  std::atomic<double> currentFreq_{440.0};
  std::atomic<bool> stereoEnabled_{true};
  std::atomic<bool> running_{false};
  std::atomic<int32_t> preferredDeviceId_{-1};
  float therapyRouterSampleRate_ = 0.0f;
  float phase2RouterSampleRate_ = 0.0f;
  std::atomic<bool> therapySessionActive_{false};
  std::atomic<bool> therapyStopPending_{false};
  LogCallback logCb_ = nullptr;
  OutputLostCallback outputLostCb_ = nullptr;

  void finalizeTherapyStopLocked();
  void log(const char *msg) {
    if (logCb_)
      logCb_(msg);
#if defined(__ANDROID__)
    else {
      __android_log_print(ANDROID_LOG_INFO, "AudioEngine", "%s", msg);
    }
#endif
  }
};
