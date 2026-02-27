/// Minimal control surface used by session/debug orchestration.
///
/// [AudioEngine] implements this contract. A smaller interface keeps
/// session logic testable without native FFI.
abstract class AudioControl {
  bool start();
  bool get isRunning;
  void setFrequency(double hz);
  void setAmplitude(double amp);
}
