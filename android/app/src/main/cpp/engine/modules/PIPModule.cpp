#include "PIPModule.h"

#include <cmath>

namespace {
constexpr float kPipEnvelopeSmoothMs = 3.0f;

float smoothingCoeffFromMs(float timeMs, double sampleRate) {
  if (timeMs <= 0.0f || sampleRate <= 0.0) {
    return 0.0f;
  }
  const float smoothingSamples =
      (timeMs * 0.001f) * static_cast<float>(sampleRate);
  return std::exp(-1.0f / smoothingSamples);
}
} // namespace

void PIPModule::init(double sampleRate) {
  sampleRate_ = sampleRate;
  pipEnvCoeff_ = smoothingCoeffFromMs(kPipEnvelopeSmoothMs, sampleRate_);
}

void PIPModule::reset() {
  samplesUntilToggle_ = 0;
  isSilent_ = false;
  envelope_ = 0.0f;
}

float PIPModule::process(double baseFreq, float baseAmp, float pipInterval,
                         float pipDuration) {
  if (samplesUntilToggle_ <= 0) {
    if (isSilent_) {
      samplesUntilToggle_ = (int)(sampleRate_ * pipInterval);
    } else {
      samplesUntilToggle_ = (int)(sampleRate_ * pipDuration);
    }
    isSilent_ = !isSilent_;
  }
  samplesUntilToggle_--;

  const float target = isSilent_ ? 0.0f : 1.0f;
  envelope_ = target + pipEnvCoeff_ * (envelope_ - target);

  mainOsc_.setTargetFrequency(baseFreq);
  float sample = mainOsc_.process();
  return sample * baseAmp * envelope_;
}
