import 'package:flutter/material.dart';

import '../../../edge_detection/edge_detection_controller.dart';
import '../../../models/edge_detection_result.dart';
import 'edge_detection_processing_screen.dart';

class EdgeDetectionCompleteScreen extends StatefulWidget {
  const EdgeDetectionCompleteScreen({super.key, required this.controller});

  final EdgeDetectionController controller;

  @override
  State<EdgeDetectionCompleteScreen> createState() =>
      _EdgeDetectionCompleteScreenState();
}

class _EdgeDetectionCompleteScreenState extends State<EdgeDetectionCompleteScreen> {
  bool _busy = false;

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final EdgeDetectionResult? result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EdgeDetectionProcessingScreen(controller: widget.controller),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              'Test Complete',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _finish,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finish'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

