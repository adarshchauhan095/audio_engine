#pragma once

#include <oboe/Oboe.h>

#include <atomic>
#include <memory>
#include <mutex>

#include "EventScheduler.h"
#include "ParameterSmoother.h"
#include "TherapyRouter.h"
#include "VoiceManager.h"

/// Engine core: Oboe stream + DSP parameter control.
///
/// Existing behavior is preserved for start/stop, amplitude, and
/// frequency updates. New scheduler/session hooks are optional.
class AudioEngine : public oboe::AudioStreamDataCallback {
public:
  ~AudioEngine();

  bool start();
  void stop();
  bool isRunning() const;

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

  typedef void (*LogCallback)(const char *);
  void setLogCallback(LogCallback cb) { logCb_ = cb; }

  oboe::DataCallbackResult onAudioReady(oboe::AudioStream *, void *audioData,
                                        int32_t numFrames) override;

private:
  std::mutex mutex_;
  std::shared_ptr<oboe::AudioStream> stream_;

  VoiceManager voiceManager_;
  EventScheduler eventScheduler_;
  ParameterSmoother amplitudeSmoother_;
  ParameterSmoother transportSmoother_;
  TherapyRouter therapyRouter_;

  std::atomic<float> amplitudeTarget_{0.3f};
  std::atomic<double> currentFreq_{440.0};
  std::atomic<bool> stereoEnabled_{true};
  std::atomic<bool> running_{false};
  LogCallback logCb_ = nullptr;

  void log(const char *msg) {
    if (logCb_)
      logCb_(msg);
  }
};
