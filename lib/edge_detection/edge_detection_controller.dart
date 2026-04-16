import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/edge_detection_result.dart';
import '../session/audio_runtime_controller.dart';
import '../storage/edge_detection_storage.dart';

class EdgeDetectionController extends ChangeNotifier {
  EdgeDetectionController(this._runtime);

  final AudioRuntimeController _runtime;

  static const List<double> testFrequenciesHz = <double>[
    500,
    1000,
    2000,
    4000,
    6000,
    8000,
  ];

  static const double defaultSliderValue = 0.5;

  double? _amsFrequencyHz;
  EdgeZone? _edgeZoneInitial;

  final Map<double, double> _rawGainValuesByHz = <double, double>{};
  List<double>? _gainProfile;
  EdgeZone? _edgeZoneFinal;
  EdgeDetectionResult? _result;

  double? get amsFrequencyHz => _amsFrequencyHz;
  EdgeZone? get edgeZoneInitial => _edgeZoneInitial;
  EdgeZone? get edgeZoneFinal => _edgeZoneFinal;
  EdgeDetectionResult? getEdgeDetectionResult() => _result;
  ValueListenable<bool> get playing => _runtime.playing;

  Map<double, double> get rawGainValuesByHz =>
      Map<double, double>.unmodifiable(_rawGainValuesByHz);

  void initEdgeDetection({required double? amsFrequencyHz}) {
    if (amsFrequencyHz == null || !amsFrequencyHz.isFinite) {
      _amsFrequencyHz = null;
      _edgeZoneInitial = null;
      _rawGainValuesByHz.clear();
      _gainProfile = null;
      _edgeZoneFinal = null;
      _result = null;
      notifyListeners();
      return;
    }

    _amsFrequencyHz = amsFrequencyHz;
    _edgeZoneInitial = computeEdgeZoneInitial();
    _rawGainValuesByHz.clear();
    for (final hz in testFrequenciesHz) {
      _rawGainValuesByHz[hz] = defaultSliderValue;
    }
    _gainProfile = null;
    _edgeZoneFinal = null;
    _result = null;

    _runtime.prepareForLiveToneControls();
    notifyListeners();
  }

  EdgeZone computeEdgeZoneInitial() {
    final double f = _amsFrequencyHz ?? 0.0;
    if (f <= 0.0 || !f.isFinite) {
      return const EdgeZone(lowHz: 0, highHz: 0);
    }
    final double factor = math.pow(2.0, 1.0 / 3.0).toDouble();
    final double low = (f / factor).clamp(
      AudioRuntimeController.freqMin,
      AudioRuntimeController.freqMax,
    );
    final double high = (f * factor).clamp(
      AudioRuntimeController.freqMin,
      AudioRuntimeController.freqMax,
    );
    return EdgeZone(lowHz: low, highHz: high);
  }

  void storeRawGainValues({required double frequencyHz, required double gain}) {
    if (!testFrequenciesHz.contains(frequencyHz)) return;
    final double clamped = gain.clamp(0.0, 1.0);
    _rawGainValuesByHz[frequencyHz] = clamped;
    notifyListeners();
  }

  List<double> normalizeGainProfile() {
    final List<double> raw = testFrequenciesHz
        .map((double hz) => (_rawGainValuesByHz[hz] ?? defaultSliderValue))
        .map((double v) => v.clamp(0.0, 1.0))
        .toList();
    final double med = _median(raw);
    final List<double> normalized = raw.map((double v) => v - med).toList();
    _gainProfile = normalized;
    notifyListeners();
    return normalized;
  }

  EdgeZone computeFinalEdgeZone() {
    final EdgeZone initial = _edgeZoneInitial ?? computeEdgeZoneInitial();
    final List<double> gain = _gainProfile ?? normalizeGainProfile();
    if (gain.isEmpty) return initial;

    int maxIdx = 0;
    double maxV = gain[0];
    for (int i = 1; i < gain.length; i++) {
      if (gain[i] > maxV) {
        maxV = gain[i];
        maxIdx = i;
      }
    }

    // Build band edges using geometric midpoints between adjacent test freqs.
    final List<double> freqs = testFrequenciesHz;
    final List<double> lowEdges = List<double>.filled(freqs.length, 0.0);
    final List<double> highEdges = List<double>.filled(freqs.length, 0.0);
    for (int i = 0; i < freqs.length; i++) {
      final double left = i == 0
          ? freqs[i] / math.sqrt(freqs[i + 1] / freqs[i])
          : math.sqrt(freqs[i - 1] * freqs[i]);
      final double right = i == freqs.length - 1
          ? freqs[i] * math.sqrt(freqs[i] / freqs[i - 1])
          : math.sqrt(freqs[i] * freqs[i + 1]);
      lowEdges[i] = left;
      highEdges[i] = right;
    }

    // Choose a contiguous "peak zone" around the strongest normalized response.
    // Threshold is relative to the peak to keep behavior stable across users.
    const double relThreshold = 0.15;
    final double threshold = maxV - relThreshold;

    int start = maxIdx;
    int end = maxIdx;
    while (start - 1 >= 0 && gain[start - 1] >= threshold) {
      start--;
    }
    while (end + 1 < gain.length && gain[end + 1] >= threshold) {
      end++;
    }

    double low = lowEdges[start];
    double high = highEdges[end];

    // Clamp final zone to initial edge zone.
    low = low.clamp(initial.lowHz, initial.highHz);
    high = high.clamp(initial.lowHz, initial.highHz);

    if (high <= low) return initial;
    return EdgeZone(lowHz: low, highHz: high);
  }

  bool get canFinish {
    if (_amsFrequencyHz == null) return false;
    for (final hz in testFrequenciesHz) {
      final double? v = _rawGainValuesByHz[hz];
      if (v == null) return false;
      if (v < 0.0 || v > 1.0) return false;
    }
    return true;
  }

  Future<EdgeDetectionResult?> finishAndPersist() async {
    if (!canFinish) return null;
    final double amsHz = _amsFrequencyHz!;
    final EdgeZone initial = _edgeZoneInitial ?? computeEdgeZoneInitial();
    final List<double> raw = testFrequenciesHz
        .map((double hz) => (_rawGainValuesByHz[hz] ?? defaultSliderValue))
        .map((double v) => v.clamp(0.0, 1.0))
        .toList();
    final List<double> normalized = _gainProfile ?? normalizeGainProfile();
    final EdgeZone finalZone = computeFinalEdgeZone();

    final EdgeDetectionResult out = EdgeDetectionResult(
      amsFrequencyHz: amsHz,
      rawGainValues: raw,
      gainProfile: normalized,
      edgeZoneInitial: initial,
      edgeZoneFinal: finalZone,
    );
    _result = out;
    _edgeZoneFinal = finalZone;
    notifyListeners();
    await EdgeDetectionStorage.saveResult(out);
    return out;
  }

  void setTone({required double frequencyHz, required double gain01}) {
    _runtime.setFrequency(frequencyHz);
    _runtime.setAmplitude(gain01.clamp(0.0, 1.0));
  }

  void toggleTone() => _runtime.togglePlay();

  void stopTone() => _runtime.stopPlayback();

  double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final List<double> sorted = List<double>.from(values)..sort();
    final int n = sorted.length;
    final int mid = n ~/ 2;
    if (n.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

