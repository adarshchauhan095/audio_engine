import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/hearing_threshold_result.dart';
import '../session/audio_runtime_controller.dart';

enum ThresholdDirection { up, down }

class HearingThresholdController extends ChangeNotifier {
  HearingThresholdController(this._runtime);

  final AudioRuntimeController _runtime;

  static const List<double> testFrequenciesHz = <double>[
    500,
    1000,
    2000,
    4000,
    6000,
    8000,
  ];

  double? _amsFrequencyHz;

  int _index = 0;
  double _level = 0.5;

  ThresholdDirection? _prevDir;
  final List<double> _reversalLevels = <double>[];

  int _notHeardAtMaxCount = 0;

  bool _finished = false;
  final Map<double, double?> _thresholdByHz = <double, double?>{};

  bool get finished => _finished;
  int get index => _index;
  double get currentHz => testFrequenciesHz[_index];
  double get level => _level;
  double? get amsFrequencyHz => _amsFrequencyHz;
  List<double> get reversalLevels =>
      List<double>.unmodifiable(_reversalLevels);

  double _stepSize() {
    final int r = _reversalLevels.length;
    if (r == 0) return 0.10;
    if (r < 3) return 0.05;
    return 0.02;
  }

  bool _isMicroStepPhase() => _reversalLevels.length >= 3;

  void init({required double? amsFrequencyHz}) {
    _amsFrequencyHz = amsFrequencyHz;
    _index = 0;
    _finished = false;
    _thresholdByHz
      ..clear()
      ..addEntries(testFrequenciesHz.map((f) => MapEntry(f, null)));
    _resetFrequencyState();
    _runtime.prepareForLiveToneControls();
    _applyTone();
    notifyListeners();
  }

  void _resetFrequencyState() {
    _level = 0.5;
    _prevDir = null;
    _reversalLevels.clear();
    _notHeardAtMaxCount = 0;
  }

  void _applyTone() {
    _runtime.setFrequency(currentHz);
    _runtime.setAmplitude(_level.clamp(0.0, 1.0));
    if (!_runtime.playing.value) {
      _runtime.togglePlay();
    }
  }

  void toggleTone() => _runtime.togglePlay();

  void stopTone() => _runtime.stopPlayback();

  bool _shouldStopForThisFrequency() {
    final int reversals = _reversalLevels.length;
    if (reversals >= 6) return true;

    // If we have at least 4 reversals after entering micro-step phase.
    if (reversals >= 4 && _isMicroStepPhase()) return true;

    return false;
  }

  double _computeThresholdFromReversals() {
    final int n = _reversalLevels.length;
    if (n == 0) return _level;
    final int take = math.min(4, n);
    final List<double> last = _reversalLevels.sublist(n - take);
    final double sum = last.fold<double>(0.0, (a, b) => a + b);
    return sum / take;
  }

  void respondHeard() {
    _respond(direction: ThresholdDirection.down);
  }

  void respondNotHeard() {
    _respond(direction: ThresholdDirection.up);
  }

  void _respond({required ThresholdDirection direction}) {
    if (_finished) return;

    // Reversal detection.
    final ThresholdDirection? prev = _prevDir;
    if (prev != null && prev != direction) {
      _reversalLevels.add(_level);
    }
    _prevDir = direction;

    final double step = _stepSize();
    double next = _level + (direction == ThresholdDirection.up ? step : -step);
    next = next.clamp(0.0, 1.0);

    // Edge cases to prevent infinite loops.
    if (direction == ThresholdDirection.up && next >= 1.0) {
      _notHeardAtMaxCount++;
      if (_notHeardAtMaxCount >= 2) {
        _thresholdByHz[currentHz] = null; // not measurable
        _advanceFrequency();
        return;
      }
    } else {
      _notHeardAtMaxCount = 0;
    }

    _level = next;
    _applyTone();

    if (_shouldStopForThisFrequency()) {
      _thresholdByHz[currentHz] = _computeThresholdFromReversals().clamp(0.0, 1.0);
      _advanceFrequency();
      return;
    }

    notifyListeners();
  }

  void _advanceFrequency() {
    if (_index >= testFrequenciesHz.length - 1) {
      _finished = true;
      stopTone();
      notifyListeners();
      return;
    }

    _index++;
    _resetFrequencyState();
    _applyTone();
    notifyListeners();
  }

  HearingThresholdResult buildResult() {
    final double ams = _amsFrequencyHz ?? 0.0;
    final List<HearingThresholdPoint> points = testFrequenciesHz
        .map(
          (hz) => HearingThresholdPoint(
            frequencyHz: hz,
            thresholdGain01: _thresholdByHz[hz],
          ),
        )
        .toList(growable: false);
    return HearingThresholdResult(
      amsFrequencyHz: ams,
      points: points,
      createdAtIso: DateTime.now().toIso8601String(),
    );
  }
}

