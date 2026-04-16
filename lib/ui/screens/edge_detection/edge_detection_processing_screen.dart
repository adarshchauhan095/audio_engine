import 'dart:async';

import 'package:flutter/material.dart';

import '../../../edge_detection/edge_detection_controller.dart';
import '../../../models/edge_detection_result.dart';

class EdgeDetectionProcessingScreen extends StatefulWidget {
  const EdgeDetectionProcessingScreen({super.key, required this.controller});

  final EdgeDetectionController controller;

  @override
  State<EdgeDetectionProcessingScreen> createState() =>
      _EdgeDetectionProcessingScreenState();
}

class _EdgeDetectionProcessingScreenState
    extends State<EdgeDetectionProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Defers tone stop + computation until after first frame to avoid
    // ValueListenable notifications during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    widget.controller.stopTone();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final EdgeDetectionResult? result =
        await widget.controller.finishAndPersist();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 34,
              width: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              'Analyzing your hearing profile...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

