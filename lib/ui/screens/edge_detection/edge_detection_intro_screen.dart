import 'package:flutter/material.dart';

import '../../../edge_detection/edge_detection_controller.dart';
import '../../../session/audio_runtime_controller.dart';
import 'edge_detection_test_screen.dart';

class EdgeDetectionIntroScreen extends StatefulWidget {
  const EdgeDetectionIntroScreen({
    super.key,
    required this.runtime,
    required this.amsFrequencyHz,
  });

  final AudioRuntimeController runtime;
  final double? amsFrequencyHz;

  @override
  State<EdgeDetectionIntroScreen> createState() =>
      _EdgeDetectionIntroScreenState();
}

class _EdgeDetectionIntroScreenState extends State<EdgeDetectionIntroScreen> {
  late final EdgeDetectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EdgeDetectionController(widget.runtime)
      ..initEdgeDetection(amsFrequencyHz: widget.amsFrequencyHz);
  }

  @override
  void dispose() {
    _controller.stopTone();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canStart =
        _controller.amsFrequencyHz != null && widget.runtime.hasEngine;

    return Scaffold(
      appBar: AppBar(title: const Text('Hearing Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'Hearing Profile Intro',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Hearing Profile Check',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This quick check helps estimate your hearing sensitivity across a few tones.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: canStart
                  ? () async {
                      if (!context.mounted) return;
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EdgeDetectionTestScreen(
                            controller: _controller,
                            initialIndex: 0,
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop(result);
                    }
                  : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Start Hearing Profile Check'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Skip'),
            ),
            const SizedBox(height: 18),
            if (_controller.amsFrequencyHz == null)
              Text(
                'Missing AMS frequency. Please complete AMS first.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

