import 'dart:async';
import 'package:flutter/material.dart';

import '../../engine/audio_engine.dart';
import '../../session/audio_runtime_controller.dart';

enum TherapyModuleIndex {
  subthreshold,
  rmp,
  pip,
  sss,
  binaural,
}

class TherapyModulesMetersPanel extends StatefulWidget {
  const TherapyModulesMetersPanel({
    super.key,
    required this.runtime,
    required this.isRunning,
    required this.intensityProvider,
    required this.elapsedSecondsProvider,
    required this.subthresholdEnabled,
    required this.rmpEnabled,
    required this.pipEnabled,
    required this.sssEnabled,
    required this.binauralEnabled,
    required this.rmpDepth,
    required this.rmpRate,
    required this.pipIntervalSeconds,
    required this.pipDurationSeconds,
    required this.sidebandOffset,
    required this.sidebandIntensity,
    required this.binauralOffset,
  });

  final AudioRuntimeController runtime;
  final bool isRunning;

  final double Function() intensityProvider;
  final double Function() elapsedSecondsProvider;

  final bool subthresholdEnabled;
  final bool rmpEnabled;
  final bool pipEnabled;
  final bool sssEnabled;
  final bool binauralEnabled;

  final double rmpDepth;
  final double rmpRate;
  final double pipIntervalSeconds;
  final double pipDurationSeconds;
  final double sidebandOffset;
  final double sidebandIntensity;
  final double binauralOffset;

  @override
  State<TherapyModulesMetersPanel> createState() =>
      _TherapyModulesMetersPanelState();
}

class _TherapyModulesMetersPanelState
    extends State<TherapyModulesMetersPanel> {
  static const int _moduleCount = 5;
  static const int _historyLength = 120;
  static const Duration _tick = Duration(milliseconds: 100);

  Timer? _timer;
  int _version = 0;

  late final List<List<double>> _expectedHistory;
  late final List<List<double>> _measuredHistory;

  final List<double> _lastExpected = List<double>.filled(_moduleCount, 0.0);
  final List<double> _lastMeasured = List<double>.filled(_moduleCount, 0.0);

  @override
  void initState() {
    super.initState();
    _expectedHistory =
        List<List<double>>.generate(_moduleCount, (_) => <double>[]);
    _measuredHistory =
        List<List<double>>.generate(_moduleCount, (_) => <double>[]);
    if (widget.isRunning) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant TherapyModulesMetersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning) {
      if (widget.isRunning) {
        _clearHistory();
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  void _clearHistory() {
    for (int i = 0; i < _moduleCount; i++) {
      _expectedHistory[i].clear();
      _measuredHistory[i].clear();
      _lastExpected[i] = 0.0;
      _lastMeasured[i] = 0.0;
    }
    _version++;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      if (!widget.isRunning) return;
      _pushSample();
      setState(() {
        _version++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  double _pipActive(double elapsedSeconds) {
    if (!widget.pipEnabled) return 0.0;
    final double interval = widget.pipIntervalSeconds;
    final double duration = widget.pipDurationSeconds;
    if (interval <= 0.0 || duration <= 0.0) return 0.0;
    final double period = interval + duration;
    if (period <= 0.0) return 0.0;

    final double t = elapsedSeconds % period;
    return t < duration ? 1.0 : 0.0;
  }

  void _pushSample() {
    final double intensity = widget.intensityProvider();
    final double elapsed = widget.elapsedSecondsProvider();

    // Expected (UI-only).
    final double expectedSub =
        widget.subthresholdEnabled ? intensity : 0.0;
    final double expectedRmp =
        widget.rmpEnabled ? intensity * widget.rmpDepth : 0.0;
    final double expectedPip = widget.pipEnabled
        ? intensity * _pipActive(elapsed)
        : 0.0;
    final double expectedSss =
        widget.sssEnabled ? intensity * widget.sidebandIntensity : 0.0;
    final double expectedBinaural =
        widget.binauralEnabled ? intensity : 0.0;

    _lastExpected[0] = expectedSub;
    _lastExpected[1] = expectedRmp;
    _lastExpected[2] = expectedPip;
    _lastExpected[3] = expectedSss;
    _lastExpected[4] = expectedBinaural;

    // Measured (native meter).
    final AudioEngine? engine = widget.runtime.engine;
    double measuredSub = 0.0;
    double measuredRmp = 0.0;
    double measuredPip = 0.0;
    double measuredSss = 0.0;
    double measuredBinaural = 0.0;

    if (engine != null) {
      measuredSub = engine.getTherapyModuleMeter(0);
      measuredRmp = engine.getTherapyModuleMeter(1);
      measuredPip = engine.getTherapyModuleMeter(2);
      measuredSss = engine.getTherapyModuleMeter(3);
      measuredBinaural = engine.getTherapyModuleMeter(4);
    }

    _lastMeasured[0] = measuredSub;
    _lastMeasured[1] = measuredRmp;
    _lastMeasured[2] = measuredPip;
    _lastMeasured[3] = measuredSss;
    _lastMeasured[4] = measuredBinaural;

    final double exp0 = expectedSub.clamp(0.0, 1.0);
    final double exp1 = expectedRmp.clamp(0.0, 1.0);
    final double exp2 = expectedPip.clamp(0.0, 1.0);
    final double exp3 = expectedSss.clamp(0.0, 1.0);
    final double exp4 = expectedBinaural.clamp(0.0, 1.0);

    final double met0 = measuredSub.clamp(0.0, 1.0);
    final double met1 = measuredRmp.clamp(0.0, 1.0);
    final double met2 = measuredPip.clamp(0.0, 1.0);
    final double met3 = measuredSss.clamp(0.0, 1.0);
    final double met4 = measuredBinaural.clamp(0.0, 1.0);

    _expectedHistory[0].add(exp0);
    _expectedHistory[1].add(exp1);
    _expectedHistory[2].add(exp2);
    _expectedHistory[3].add(exp3);
    _expectedHistory[4].add(exp4);

    _measuredHistory[0].add(met0);
    _measuredHistory[1].add(met1);
    _measuredHistory[2].add(met2);
    _measuredHistory[3].add(met3);
    _measuredHistory[4].add(met4);

    for (int i = 0; i < _moduleCount; i++) {
      if (_expectedHistory[i].length > _historyLength) {
        _expectedHistory[i].removeAt(0);
      }
      if (_measuredHistory[i].length > _historyLength) {
        _measuredHistory[i].removeAt(0);
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double chartHeight = 44.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Module Graphs (Expected + Measured)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _moduleRow(
              context,
              title: 'Subthreshold',
              expected: _lastExpected[0],
              measured: _lastMeasured[0],
              moduleIndex: 0,
              expectedHistory: _expectedHistory[0],
              measuredHistory: _measuredHistory[0],
              chartHeight: chartHeight,
              enabled: widget.subthresholdEnabled,
            ),
            _moduleRow(
              context,
              title: 'RMP',
              expected: _lastExpected[1],
              measured: _lastMeasured[1],
              moduleIndex: 1,
              expectedHistory: _expectedHistory[1],
              measuredHistory: _measuredHistory[1],
              chartHeight: chartHeight,
              enabled: widget.rmpEnabled,
              extraLabel: 'rate=${widget.rmpRate.toStringAsFixed(2)} Hz, '
                  'depth=${widget.rmpDepth.toStringAsFixed(3)}',
            ),
            _moduleRow(
              context,
              title: 'PIP',
              expected: _lastExpected[2],
              measured: _lastMeasured[2],
              moduleIndex: 2,
              expectedHistory: _expectedHistory[2],
              measuredHistory: _measuredHistory[2],
              chartHeight: chartHeight,
              enabled: widget.pipEnabled,
              extraLabel:
                  'interval=${(widget.pipIntervalSeconds * 1000.0).toStringAsFixed(0)} ms, '
                  'duration=${(widget.pipDurationSeconds * 1000.0).toStringAsFixed(0)} ms',
            ),
            _moduleRow(
              context,
              title: 'SSS',
              expected: _lastExpected[3],
              measured: _lastMeasured[3],
              moduleIndex: 3,
              expectedHistory: _expectedHistory[3],
              measuredHistory: _measuredHistory[3],
              chartHeight: chartHeight,
              enabled: widget.sssEnabled,
              extraLabel:
                  'offset=${widget.sidebandOffset.toStringAsFixed(1)} Hz, '
                  'intensity=${widget.sidebandIntensity.toStringAsFixed(2)}',
            ),
            _moduleRow(
              context,
              title: 'Binaural',
              expected: _lastExpected[4],
              measured: _lastMeasured[4],
              moduleIndex: 4,
              expectedHistory: _expectedHistory[4],
              measuredHistory: _measuredHistory[4],
              chartHeight: chartHeight,
              enabled: widget.binauralEnabled,
              extraLabel:
                  'offset=${widget.binauralOffset.toStringAsFixed(1)} Hz',
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleRow(
    BuildContext context, {
    required String title,
    required double expected,
    required double measured,
    required int moduleIndex,
    required List<double> expectedHistory,
    required List<double> measuredHistory,
    required double chartHeight,
    required bool enabled,
    String? extraLabel,
  }) {
    final Color expectedColor = Theme.of(context).colorScheme.primary;
    final Color measuredColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ${enabled ? 'On' : 'Off'} | '
            'exp=${expected.toStringAsFixed(2)} '
            'meas=${measured.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (extraLabel != null)
            Text(
              extraLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 6),
          SizedBox(
            height: chartHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _ExpectedMeasuredLinePainter(
                expectedHistory: expectedHistory,
                measuredHistory: measuredHistory,
                expectedColor: expectedColor,
                measuredColor: measuredColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectedMeasuredLinePainter extends CustomPainter {
  _ExpectedMeasuredLinePainter({
    required this.expectedHistory,
    required this.measuredHistory,
    required this.expectedColor,
    required this.measuredColor,
  });

  final List<double> expectedHistory;
  final List<double> measuredHistory;
  final Color expectedColor;
  final Color measuredColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    const double pad = 6.0;

    final double plotW = w - pad * 2;
    final double plotH = h - pad * 2;

    final double baselineY = pad + plotH;

    final Paint axisPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(pad, baselineY), Offset(pad + plotW, baselineY),
        axisPaint);

    void drawLine(List<double> values, Paint paint) {
      if (values.length < 2) return;
      final int n = values.length;
      final double dx = plotW / (n - 1).clamp(1, double.infinity);
      final Path path = Path();

      for (int i = 0; i < n; i++) {
        final double v = values[i].clamp(0.0, 1.0);
        final double x = pad + i * dx;
        final double y = pad + (1.0 - v) * plotH;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }

    final Paint expectedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = expectedColor;

    final Paint measuredPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = measuredColor;

    drawLine(expectedHistory, expectedPaint);
    drawLine(measuredHistory, measuredPaint);
  }

  @override
  bool shouldRepaint(covariant _ExpectedMeasuredLinePainter oldDelegate) {
    return !listEquals(expectedHistory, oldDelegate.expectedHistory) ||
        !listEquals(measuredHistory, oldDelegate.measuredHistory) ||
        oldDelegate.expectedColor != expectedColor ||
        oldDelegate.measuredColor != measuredColor;
  }

  bool listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

