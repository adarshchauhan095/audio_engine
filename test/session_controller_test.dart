import 'package:audio_engine/engine/audio_control.dart';
import 'package:audio_engine/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAudioControl implements AudioControl {
  int startCalls = 0;
  int setFrequencyCalls = 0;
  int setAmplitudeCalls = 0;
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  bool start() {
    startCalls++;
    _running = true;
    return true;
  }

  @override
  void stop() {
    _running = false;
  }

  @override
  void setAmplitude(double amp) {
    setAmplitudeCalls++;
  }

  @override
  void setFrequency(double hz) {
    setFrequencyCalls++;
  }
}

void main() {
  test('SessionController blocks overlapping test runs', () async {
    final engine = _FakeAudioControl();
    int frequencyUpdates = 0;
    int amplitudeUpdates = 0;
    bool lastPlaying = false;

    final controller = SessionController(
      engine: engine,
      onFrequencyChanged: (_) => frequencyUpdates++,
      onAmplitudeChanged: (_) => amplitudeUpdates++,
      onPlayingChanged: (playing) => lastPlaying = playing,
      sequenceHz: const <double>[440.0, 660.0, 880.0],
      sequenceStepDelay: const Duration(milliseconds: 5),
      adaptiveSteps: 3,
      adaptiveStepDelay: const Duration(milliseconds: 1),
    );

    final Future<void> firstRun = controller.runSequenceTest();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await controller.runAdaptiveTest();
    await firstRun;

    expect(frequencyUpdates, 3);
    expect(amplitudeUpdates, 0);
    expect(engine.startCalls, 1);
    expect(engine.setFrequencyCalls, 3);
    expect(engine.setAmplitudeCalls, 0);
    expect(lastPlaying, isFalse);
    expect(controller.testInProgress, isFalse);
  });

  test('SessionController dispose blocks future runs', () async {
    final engine = _FakeAudioControl();
    int frequencyUpdates = 0;
    int amplitudeUpdates = 0;

    final controller = SessionController(
      engine: engine,
      onFrequencyChanged: (_) => frequencyUpdates++,
      onAmplitudeChanged: (_) => amplitudeUpdates++,
      onPlayingChanged: (_) {},
      adaptiveSteps: 3,
      adaptiveStepDelay: const Duration(milliseconds: 1),
    );

    controller.dispose();
    await controller.runAdaptiveTest();

    expect(frequencyUpdates, 0);
    expect(amplitudeUpdates, 0);
    expect(engine.startCalls, 0);
    expect(engine.setFrequencyCalls, 0);
    expect(engine.setAmplitudeCalls, 0);
  });

  test(
    'SessionController adaptive test executes configured step count',
    () async {
      final engine = _FakeAudioControl();
      int frequencyUpdates = 0;
      int amplitudeUpdates = 0;

      final controller = SessionController(
        engine: engine,
        onFrequencyChanged: (_) => frequencyUpdates++,
        onAmplitudeChanged: (_) => amplitudeUpdates++,
        onPlayingChanged: (_) {},
        adaptiveSteps: 5,
        adaptiveStepDelay: const Duration(milliseconds: 1),
      );

      await controller.runAdaptiveTest();

      expect(frequencyUpdates, 5);
      expect(amplitudeUpdates, 5);
      expect(engine.setFrequencyCalls, 5);
      expect(engine.setAmplitudeCalls, 5);
    },
  );
}
