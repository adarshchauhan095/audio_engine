import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../edge_detection/edge_detection_controller.dart';
import '../../../models/edge_detection_result.dart';
import 'edge_detection_complete_screen.dart';
import 'edge_detection_result_screen.dart';

class EdgeDetectionTestScreen extends StatefulWidget {
  const EdgeDetectionTestScreen({
    super.key,
    required this.controller,
    required this.initialIndex,
  });

  final EdgeDetectionController controller;
  final int initialIndex;

  @override
  State<EdgeDetectionTestScreen> createState() => _EdgeDetectionTestScreenState();
}

class _EdgeDetectionTestScreenState extends State<EdgeDetectionTestScreen> {
  late int _index;
  late double _sliderValue;

  double get _hz => EdgeDetectionController.testFrequenciesHz[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(
      0,
      EdgeDetectionController.testFrequenciesHz.length - 1,
    );
    _sliderValue =
        widget.controller.rawGainValuesByHz[_hz] ??
        EdgeDetectionController.defaultSliderValue;

    widget.controller.setTone(frequencyHz: _hz, gain01: _sliderValue);
  }

  @override
  void dispose() {
    widget.controller.stopTone();
    super.dispose();
  }

  Future<void> _next() async {
    widget.controller.storeRawGainValues(frequencyHz: _hz, gain: _sliderValue);

    final bool isLast =
        _index == EdgeDetectionController.testFrequenciesHz.length - 1;
    if (!isLast) {
      setState(() {
        _index++;
        _sliderValue =
            widget.controller.rawGainValuesByHz[_hz] ??
            EdgeDetectionController.defaultSliderValue;
      });
      widget.controller.setTone(frequencyHz: _hz, gain01: _sliderValue);
      return;
    }

    if (!mounted) return;
    final EdgeDetectionResult? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EdgeDetectionCompleteScreen(controller: widget.controller),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      // If processing screen returns null, stay on last test step.
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EdgeDetectionResultScreen(
          controller: widget.controller,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = widget.controller.playing.value;

    final String title = 'Tone at ${_hz.toStringAsFixed(0)} Hz';
    final Color primary = Theme.of(context).colorScheme.primary;
    final double progress = (_index + 1) /
        EdgeDetectionController.testFrequenciesHz.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hearing Profile Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary.withValues(alpha: 0.25), width: 10),
                  color: primary.withValues(alpha: 0.10),
                ),
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: () {
                widget.controller.toggleTone();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(isPlaying ? 'Stop' : 'Play'),
              ),
            ),
            const SizedBox(height: 18),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: primary.withValues(alpha: 0.45),
                inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
                thumbColor: primary,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _sliderValue.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                onChanged: (double v) {
                  final double clamped = v.clamp(0.0, 1.0);
                  setState(() => _sliderValue = clamped);
                  widget.controller.setTone(frequencyHz: _hz, gain01: clamped);
                },
              ),
            ),
            const SizedBox(height: 10),
            _FrequencyBars(activeHz: _hz),
            const Spacer(),
            FilledButton(
              onPressed: _next,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Next'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FrequencyBars extends StatelessWidget {
  const _FrequencyBars({required this.activeHz});

  final double activeHz;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final List<double> freqs = EdgeDetectionController.testFrequenciesHz;

    return SizedBox(
      height: 46,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final f in freqs)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: f == activeHz ? 44 : 20 + 16 * math.sin(f / 1500).abs(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: (f == activeHz
                            ? primary
                            : primary.withValues(alpha: 0.25))
                        .withValues(alpha: f == activeHz ? 0.9 : 0.25),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

