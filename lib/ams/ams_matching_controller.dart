import 'package:flutter/foundation.dart';

import '../session/audio_runtime_controller.dart';
import '../storage/ams_matching_storage.dart';
import '../storage/detected_frequency_storage.dart';

/// Distinct AMS UI / engine states (one screen per phase after start).
enum AmsPhase {
  start,
  coarse,
  fine,
  validation,
  result,
}

/// State machine for guided tinnitus frequency matching (AMS).
///
/// Frequency jumps are applied via [AudioRuntimeController.setFrequency] for
/// deterministic, engine-wide state. Coarse uses large steps; fine uses small
/// steps within a band around the coarse pick; validation uses micro steps
/// around the fine pick.
class AmsMatchingController extends ChangeNotifier {
  AmsMatchingController(this._runtime);

  final AudioRuntimeController _runtime;

  AmsPhase _phase = AmsPhase.start;

  /// Starting point for coarse matching (Hz).
  static const double initialFrequencyHz = 4000.0;

  static const double coarseStepHz = 100.0;
  static const double fineStepHz = 5.0;
  static const double microStepHz = 1.0;

  /// Fine matching stays within ± this width (Hz) of the stored coarse frequency.
  static const double fineBandHalfWidthHz = 100.0;

  /// Validation micro-adjustments stay within ± this width (Hz) of the fine pick.
  static const double validationBandHalfWidthHz = 25.0;

  double _currentHz = initialFrequencyHz;

  double? _coarseHz;
  double? _fineHz;
  double? _finalHz;

  AmsPhase get phase => _phase;
  double get currentHz => _currentHz;
  double? get coarseFrequency => _coarseHz;
  double? get fineFrequency => _fineHz;
  double? get finalFrequency => _finalHz;

  double _globalMin() => AudioRuntimeController.freqMin;
  double _globalMax() => AudioRuntimeController.freqMax;

  void _emitFrequency(double hz) {
    final double g = hz.clamp(_globalMin(), _globalMax());
    _currentHz = g;
    _runtime.setFrequency(g);
    notifyListeners();
  }

  double _fineLow() {
    final double c = _coarseHz ?? _currentHz;
    return (c - fineBandHalfWidthHz).clamp(_globalMin(), _globalMax());
  }

  double _fineHigh() {
    final double c = _coarseHz ?? _currentHz;
    return (c + fineBandHalfWidthHz).clamp(_globalMin(), _globalMax());
  }

  double _validationLow() {
    final double f = _fineHz ?? _currentHz;
    return (f - validationBandHalfWidthHz).clamp(_globalMin(), _globalMax());
  }

  double _validationHigh() {
    final double f = _fineHz ?? _currentHz;
    return (f + validationBandHalfWidthHz).clamp(_globalMin(), _globalMax());
  }

  /// Clears module state and primes engine for a new AMS run.
  Future<void> beginMatching() async {
    _coarseHz = null;
    _fineHz = null;
    _finalHz = null;
    _phase = AmsPhase.coarse;
    _runtime.prepareForAmsMatching();
    _emitFrequency(initialFrequencyHz);
    if (!_runtime.playing.value) {
      _runtime.togglePlay();
    }
    await AmsMatchingStorage.clearSession();
  }

  void higher() {
    switch (_phase) {
      case AmsPhase.coarse:
        _emitFrequency(_currentHz + coarseStepHz);
        break;
      case AmsPhase.fine:
        _emitFrequency(
          (_currentHz + fineStepHz).clamp(_fineLow(), _fineHigh()),
        );
        break;
      case AmsPhase.validation:
        _emitFrequency(
          (_currentHz + microStepHz).clamp(_validationLow(), _validationHigh()),
        );
        break;
      default:
        break;
    }
  }

  void lower() {
    switch (_phase) {
      case AmsPhase.coarse:
        _emitFrequency(_currentHz - coarseStepHz);
        break;
      case AmsPhase.fine:
        _emitFrequency(
          (_currentHz - fineStepHz).clamp(_fineLow(), _fineHigh()),
        );
        break;
      case AmsPhase.validation:
        _emitFrequency(
          (_currentHz - microStepHz).clamp(_validationLow(), _validationHigh()),
        );
        break;
      default:
        break;
    }
  }

  /// Coarse OK → store coarse frequency, enter fine matching.
  Future<void> confirmCoarse() async {
    if (_phase != AmsPhase.coarse) return;
    _coarseHz = _currentHz;
    await AmsMatchingStorage.saveCoarseFrequency(_coarseHz!);
    _phase = AmsPhase.fine;
    _emitFrequency(_currentHz.clamp(_fineLow(), _fineHigh()));
  }

  /// Fine OK → store fine frequency, enter validation.
  Future<void> confirmFine() async {
    if (_phase != AmsPhase.fine) return;
    _fineHz = _currentHz;
    await AmsMatchingStorage.saveFineFrequency(_fineHz!);
    _phase = AmsPhase.validation;
    _emitFrequency(_currentHz.clamp(_validationLow(), _validationHigh()));
  }

  /// Validation confirm → store final frequency, show result.
  Future<void> confirmValidation() async {
    if (_phase != AmsPhase.validation) return;
    _finalHz = _currentHz;
    await AmsMatchingStorage.saveFinalFrequency(_finalHz!);
    _phase = AmsPhase.result;
    stopPlaybackIfOwned();
    notifyListeners();
  }

  /// Writes the matched frequency to the app-wide detected frequency store.
  Future<bool> saveAndContinue() async {
    if (_finalHz == null) return false;
    return DetectedFrequencyStorage.saveDetectedFrequency(_finalHz!);
  }

  /// Stops AMS tone when leaving the flow (does not alter other modules).
  void stopPlaybackIfOwned() {
    if (_runtime.playing.value) {
      _runtime.stopPlayback();
    }
  }
}
