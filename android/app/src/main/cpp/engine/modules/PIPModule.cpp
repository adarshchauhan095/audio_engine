#include "PIPModule.h"

void PIPModule::init(double sampleRate) { sampleRate_ = sampleRate; }

void PIPModule::reset() {
  samplesUntilToggle_ = 0;
  isSilent_ = false;
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

  mainOsc_.setTargetFrequency(baseFreq);
  float sample = mainOsc_.process();
  return isSilent_ ? 0.0f : (sample * baseAmp);
}
