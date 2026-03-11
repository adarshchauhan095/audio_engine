#include "SidebandModule.h"

void SidebandModule::init(double sampleRate) {}

float SidebandModule::process(double baseFreq, float baseAmp,
                              float sidebandOffset, float sidebandIntensity) {
  lowerSideband_.setTargetFrequency(baseFreq - sidebandOffset);
  upperSideband_.setTargetFrequency(baseFreq + sidebandOffset);
  mainOsc_.setTargetFrequency(baseFreq);

  // Scale the sidebands using the intensity parameter to allow mixing depth
  float s1 = lowerSideband_.process() * sidebandIntensity;
  float s2 = upperSideband_.process() * sidebandIntensity;
  float m = mainOsc_.process();

  // Normalize mix so it never clips baseline amplitude
  return (s1 + s2 + m) * 0.333f * baseAmp;
}
