import 'package:flutter/material.dart';

import '../../../edge_detection/edge_detection_controller.dart';
import '../../../models/edge_detection_result.dart';
import 'edge_detection_test_screen.dart';

class EdgeDetectionResultScreen extends StatelessWidget {
  const EdgeDetectionResultScreen({
    super.key,
    required this.controller,
    required this.result,
  });

  final EdgeDetectionController controller;
  final EdgeDetectionResult result;

  static String _formatKHz(double hz) {
    final double khz = hz / 1000.0;
    if (khz >= 10) return '${khz.toStringAsFixed(0)} kHz';
    return '${khz.toStringAsFixed(1)} kHz';
  }

  @override
  Widget build(BuildContext context) {
    final EdgeZone zone = result.edgeZoneFinal;
    final String rangeLabel =
        '${_formatKHz(zone.lowHz)} – ${_formatKHz(zone.highHz)}';
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Ready')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Profile Ready',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your most relevant hearing range:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              rangeLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _GainBars(
              values: result.gainProfile,
              color: primary,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(result);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Continue'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                controller.initEdgeDetection(amsFrequencyHz: controller.amsFrequencyHz);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => EdgeDetectionTestScreen(
                      controller: controller,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Redo Test'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GainBars extends StatelessWidget {
  const _GainBars({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(height: 120);
    }
    final double maxAbs = values
        .map((v) => v.abs())
        .fold<double>(0.0, (a, b) => a > b ? a : b);
    final double scale = maxAbs <= 0 ? 1.0 : maxAbs;

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (values[i].abs() / scale).clamp(0.05, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      EdgeDetectionController.testFrequenciesHz[i]
                          .toStringAsFixed(0),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

