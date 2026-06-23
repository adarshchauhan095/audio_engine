#include "AudioEngine.h"
#include "TherapyConfig.h"

#include <algorithm>

namespace {
constexpr float kAmplitudeSmoothingMs = 8.0f;
constexpr float kTransportRampMs = 30.0f;
constexpr float kTherapySessionFadeMs = 50.0f;
constexpr float kTherapyStopSilenceThreshold = 0.001f;
} // namespace

AudioEngine::~AudioEngine() {
  std::lock_guard<std::mutex> lock(mutex_);
  outputLostCb_ = nullptr;
  if (stream_) {
    stream_->requestStop();
    stream_->close();
    stream_.reset();
  }
}

void AudioEngine::resetOutputStream() {
  std::lock_guard<std::mutex> lock(mutex_);
  running_.store(false, std::memory_order_relaxed);
  if (stream_) {
    transportSmoother_.setTarget(0.0f);
    stream_->requestStop();
    stream_->close();
    stream_.reset();
    therapyRouterSampleRate_ = 0.0f;
#ifndef NDEBUG
    log("Output stream reset for route recovery");
#endif
  }
}

void AudioEngine::setPreferredOutputDeviceId(int32_t deviceId) {
  preferredDeviceId_.store(deviceId, std::memory_order_relaxed);
}

void AudioEngine::onErrorBeforeClose(oboe::AudioStream *stream,
                                     oboe::Result error) {
#ifndef NDEBUG
  log("Oboe stream error; releasing stream handle");
#endif
  (void)error;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (stream_.get() == stream) {
      stream_.reset();
    }
    running_.store(false, std::memory_order_relaxed);
  }
  if (outputLostCb_) {
    outputLostCb_();
  }
}

bool AudioEngine::start() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (stream_) {
    amplitudeSmoother_.setTarget(
        amplitudeTarget_.load(std::memory_order_relaxed));
    transportSmoother_.setTarget(1.0f);
    running_.store(true, std::memory_order_relaxed);
#ifndef NDEBUG
    log("Engine started");
#endif
    return true;
  }

  oboe::AudioStreamBuilder builder;
  builder.setDirection(oboe::Direction::Output)
      ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
      ->setSharingMode(oboe::SharingMode::Exclusive)
      ->setFormat(oboe::AudioFormat::Float)
      ->setChannelCount(2)
      ->setSampleRate(48000)
#if defined(__ANDROID__)
      ->setUsage(oboe::Usage::Media)
      ->setContentType(oboe::ContentType::Music)
#endif
      ->setDataCallback(this)
      ->setErrorCallback(this);

  const int32_t devId = preferredDeviceId_.load(std::memory_order_relaxed);
  if (devId >= 0) {
    builder.setDeviceId(devId);
  }

  if (builder.openStream(stream_) != oboe::Result::OK) {
    return false;
  }

  const float currentAmplitude =
      amplitudeTarget_.load(std::memory_order_relaxed);
  amplitudeSmoother_.setSmoothingTimeMs(
      kAmplitudeSmoothingMs, static_cast<float>(stream_->getSampleRate()));
  amplitudeSmoother_.reset(currentAmplitude);

  transportSmoother_.setSmoothingTimeMs(
      kTransportRampMs, static_cast<float>(stream_->getSampleRate()));
  transportSmoother_.reset(0.0f);
  transportSmoother_.setTarget(1.0f);

  therapySessionGainSmoother_.setSmoothingTimeMs(
      kTherapySessionFadeMs, static_cast<float>(stream_->getSampleRate()));
  voiceManager_.resetPhases();

  if (stream_->requestStart() != oboe::Result::OK) {
    stream_->close();
    stream_.reset();
    return false;
  }

  preferredDeviceId_.store(-1, std::memory_order_relaxed);

  running_.store(true, std::memory_order_relaxed);
#ifndef NDEBUG
  log("Engine started");
#endif
  return true;
}

void AudioEngine::stop() {
  std::lock_guard<std::mutex> lock(mutex_);
  running_.store(false, std::memory_order_relaxed);
#ifndef NDEBUG
  log("Engine stopped");
#endif
  if (stream_) {
    transportSmoother_.setTarget(0.0f);
  }
}

bool AudioEngine::isRunning() const {
  return running_.load(std::memory_order_relaxed);
}

void AudioEngine::setFrequency(float hz) {
  currentFreq_.store(hz, std::memory_order_relaxed);
  voiceManager_.setFrequency(hz);
}

void AudioEngine::setTargetFrequency(double hz) {
  currentFreq_.store(hz, std::memory_order_relaxed);
  voiceManager_.setTargetFrequency(hz);
}

void AudioEngine::setAmplitude(float amp) {
  const float clampedAmp = std::clamp(amp, 0.0f, 1.0f);
  amplitudeTarget_.store(clampedAmp, std::memory_order_relaxed);
  amplitudeSmoother_.setTarget(clampedAmp);
}

void AudioEngine::scheduleSequence() {
  eventScheduler_.scheduleDefaultSequence();
}

void AudioEngine::startSession() { eventScheduler_.startSession(); }

void AudioEngine::stopSession() { eventScheduler_.stopSession(); }

void AudioEngine::setStereoEnabled(bool enabled) {
  stereoEnabled_.store(enabled, std::memory_order_relaxed);
}

void AudioEngine::finalizeTherapyStopLocked() {
  therapyRouter_.updateConfig(TherapyConfig::inactive());
  therapySessionActive_.store(false, std::memory_order_release);
  therapyStopPending_.store(false, std::memory_order_release);
}

int AudioEngine::therapyStart(const TherapyConfig &config) {
  std::lock_guard<std::mutex> lock(mutex_);
  therapyStopPending_.store(false, std::memory_order_release);

  const float sr = stream_ ? static_cast<float>(stream_->getSampleRate()) : 48000.0f;
  // IMPORTANT: Do not re-init the router on every start; that can introduce
  // discontinuities (pops/squeaks) when the user toggles therapy rapidly.
  // Only re-init if the sample rate changed or the stream was reopened.
  if (therapyRouterSampleRate_ <= 0.0f || std::fabs(therapyRouterSampleRate_ - sr) > 1e-3f) {
    therapyRouter_.init(sr);
    therapyRouterSampleRate_ = sr;
    therapySessionGainSmoother_.setSmoothingTimeMs(kTherapySessionFadeMs, sr);
  }

  voiceManager_.resetPhases();
  therapyRouter_.resetAllModulePhases();
  therapyRouter_.resetModuleGains();

  therapySessionGainSmoother_.reset(0.0f);
  therapySessionGainSmoother_.setTarget(1.0f);
  therapySessionActive_.store(true, std::memory_order_release);

  therapyRouter_.updateConfig(config);
  log("Therapy started");
  return 1;
}

int AudioEngine::therapyUpdate(const TherapyConfig &config) {
  std::lock_guard<std::mutex> lock(mutex_);
  therapyRouter_.updateConfig(config);
//  log("Therapy updated");
  return 1;
}

int AudioEngine::therapyStop() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!therapySessionActive_.load(std::memory_order_acquire)) {
    finalizeTherapyStopLocked();
    log("Therapy stopped");
    return 1;
  }
  therapyStopPending_.store(true, std::memory_order_release);
  therapySessionGainSmoother_.setTarget(0.0f);
  log("Therapy stopping (fade out)");
  return 1;
}

int AudioEngine::phase2Start(const Phase2Config& config) {
  std::lock_guard<std::mutex> lock(mutex_);
  const float sr =
      stream_ ? static_cast<float>(stream_->getSampleRate()) : 48000.0f;
  if (phase2RouterSampleRate_ <= 0.0f ||
      std::fabs(phase2RouterSampleRate_ - sr) > 1e-3f) {
    phase2Router_.init(sr);
    phase2RouterSampleRate_ = sr;
  }
  phase2Router_.updateConfig(config);
#ifndef NDEBUG
  log("Phase2 started");
#endif
  return 1;
}

int AudioEngine::phase2Update(const Phase2Config& config) {
  std::lock_guard<std::mutex> lock(mutex_);
  phase2Router_.updateConfig(config);
  return 1;
}

int AudioEngine::phase2Stop() {
  std::lock_guard<std::mutex> lock(mutex_);
  Phase2Config empty;
  empty.enabled = false;
  phase2Router_.updateConfig(empty);
#ifndef NDEBUG
  log("Phase2 stopped");
#endif
  return 1;
}

void AudioEngine::setPhase52GeneratorParams(int generatorId, float p1, float p2, float p3, float p4, float p5) {
  std::lock_guard<std::mutex> lock(mutex_);
  // generatorId mapping: 
  // 1 = PhaseBreaker
  // 2 = AntiCorrelation
  // 3 = ContrastRemap
  // 4 = SalienceScrambler
  // 5 = NullModel
  // 0 = Disable All
  
  if (generatorId == 0) {
      phase52QaConfig_.enablePhaseBreaker = false;
      phase52QaConfig_.enableAntiCorrelation = false;
      phase52QaConfig_.enableContrastRemap = false;
      phase52QaConfig_.enableSalienceScrambler = false;
      phase52QaConfig_.enableNullModel = false;
      therapyRouter_.updateConfig(TherapyConfig::inactive());
      return;
  }
  
  if (generatorId == 1) {
      phase52QaConfig_.enablePhaseBreaker = true;
      phase52QaConfig_.phaseBreakerParams.baseFrequency = p1;
      phase52QaConfig_.phaseBreakerParams.driftAmount = p2;
      phase52QaConfig_.phaseBreakerParams.driftSpeed = p3;
      phase52QaConfig_.phaseBreakerParams.phaseJitter = p4;
      phase52QaConfig_.phaseBreakerParams.amplitude = p5;
  } else if (generatorId == 2) {
      phase52QaConfig_.enableAntiCorrelation = true;
      phase52QaConfig_.antiCorrelationParams.baseFrequency = p1;
      phase52QaConfig_.antiCorrelationParams.inversionDepth = p2;
      phase52QaConfig_.antiCorrelationParams.delayMs = p3;
      phase52QaConfig_.antiCorrelationParams.amplitude = p4;
  } else if (generatorId == 3) {
      phase52QaConfig_.enableContrastRemap = true;
      phase52QaConfig_.contrastRemapParams.baseFrequency = p1;
      phase52QaConfig_.contrastRemapParams.contrastWidth = p2;
      phase52QaConfig_.contrastRemapParams.contrastShift = p3;
      phase52QaConfig_.contrastRemapParams.modulationSpeed = p4;
      phase52QaConfig_.contrastRemapParams.amplitude = p5;
  } else if (generatorId == 4) {
      phase52QaConfig_.enableSalienceScrambler = true;
      phase52QaConfig_.salienceScramblerParams.burstRate = p1;
      phase52QaConfig_.salienceScramblerParams.burstLengthMs = p2;
      phase52QaConfig_.salienceScramblerParams.jitterAmount = p3;
      phase52QaConfig_.salienceScramblerParams.amplitude = p4;
  } else if (generatorId == 5) {
      phase52QaConfig_.enableNullModel = true;
      phase52QaConfig_.nullModelParams.amplitude = p1;
      phase52QaConfig_.nullModelParams.noiseFloor = p2;
      phase52QaConfig_.nullModelParams.stability = p3;
  }

  // Force active state to bypass standard modules but allow Phase 5.2
  // We use therapyUpdate to push these changes safely into the router.
  therapyRouter_.updateConfig(phase52QaConfig_);
}

void AudioEngine::getDiagnostics(float* outRms, float* outPeak, int* outNanCount, int* outClipCount) {
  int samples = diagSampleCount_.exchange(0, std::memory_order_relaxed);
  float rmsSum = diagRmsSum_.exchange(0.0f, std::memory_order_relaxed);
  
  if (samples > 0) {
      *outRms = std::sqrt(rmsSum / static_cast<float>(samples));
  } else {
      *outRms = 0.0f;
  }
  
  *outPeak = diagPeak_.exchange(0.0f, std::memory_order_relaxed);
  *outNanCount = diagNanCount_.load(std::memory_order_relaxed);
  *outClipCount = diagClipCount_.load(std::memory_order_relaxed);
}

oboe::DataCallbackResult AudioEngine::onAudioReady(oboe::AudioStream *audioStream,
                                                   void *audioData,
                                                   int32_t numFrames) {
  float *out = static_cast<float *>(audioData);
  bool isStereo = stereoEnabled_.load(std::memory_order_relaxed);

  int32_t channelCount = 2;
  if (audioStream != nullptr) {
    channelCount = audioStream->getChannelCount();
    if (channelCount < 1) {
      channelCount = 1;
    }
  }

  const bool therapySession =
      therapySessionActive_.load(std::memory_order_acquire);

  for (int32_t i = 0; i < numFrames; ++i) {
    const float transport = transportSmoother_.process();
    const float amp = amplitudeSmoother_.process();
    const float sessionGain =
        therapySession ? therapySessionGainSmoother_.process() : 1.0f;

    float left = 0.0f;
    float right = 0.0f;

    if (phase2Router_.isActive()) {
      StereoSample sr = phase2Router_.process();
      if (!isStereo) {
        const float mono = (sr.left + sr.right) * 0.5f;
        sr.left = mono;
        sr.right = mono;
      }
      left = sr.left * sessionGain * transport;
      right = sr.right * sessionGain * transport;
      voiceManager_.process();
    } else if (therapyRouter_.isActive()) {
      StereoSample sr = therapyRouter_.process();
      if (!isStereo) {
        const float mono = (sr.left + sr.right) * 0.5f;
        sr.left = mono;
        sr.right = mono;
      }
      left = sr.left * sessionGain * transport;
      right = sr.right * sessionGain * transport;
      voiceManager_.process();
    } else {
      const float mono =
          sessionGain * transport * amp * voiceManager_.process();
      left = mono;
      right = mono;
    }

    if (therapyStopPending_.load(std::memory_order_acquire) &&
        sessionGain < kTherapyStopSilenceThreshold) {
      bool pending = true;
      if (therapyStopPending_.compare_exchange_strong(
              pending, false, std::memory_order_acq_rel)) {
        therapyRouter_.updateConfig(TherapyConfig::inactive());
        therapySessionActive_.store(false, std::memory_order_release);
      }
    }

    // Diagnostics Gathering (Phase 5.2 QA testing)
    float monoSum = 0.5f * (left + right);
    if (std::isnan(monoSum) || std::isinf(monoSum)) {
        diagNanCount_.fetch_add(1, std::memory_order_relaxed);
        left = 0.0f; right = 0.0f; // Silence invalid values
    } else {
        float absLeft = std::fabs(left);
        float absRight = std::fabs(right);
        float localPeak = std::max(absLeft, absRight);
        
        if (localPeak > 1.0f) {
            diagClipCount_.fetch_add(1, std::memory_order_relaxed);
        }
        
        float currentPeak = diagPeak_.load(std::memory_order_relaxed);
        while (localPeak > currentPeak && !diagPeak_.compare_exchange_weak(currentPeak, localPeak, std::memory_order_relaxed)) {}
        
        float rmsValue = (left * left + right * right) * 0.5f;
        float currentSum = diagRmsSum_.load(std::memory_order_relaxed);
        while (!diagRmsSum_.compare_exchange_weak(currentSum, currentSum + rmsValue, std::memory_order_relaxed)) {}
        
        diagSampleCount_.fetch_add(1, std::memory_order_relaxed);
    }

    const size_t base = static_cast<size_t>(i) * static_cast<size_t>(channelCount);
    if (channelCount == 1) {
      out[base] = 0.5f * (left + right);
    } else {
      out[base + 0] = left;
      out[base + 1] = right;
      for (int32_t c = 2; c < channelCount; ++c) {
        out[base + static_cast<size_t>(c)] = 0.5f * (left + right);
      }
    }
  }
  return oboe::DataCallbackResult::Continue;
}
