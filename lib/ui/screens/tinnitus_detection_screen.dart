import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../tinnitus_detection_section.dart';

class TinnitusDetectionScreen extends StatelessWidget {
  const TinnitusDetectionScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Use this page for individual tinnitus frequency detection. '
                  'Save, load, and sweep controls are isolated from other screens.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TinnitusDetectionSection(engine: runtime.engine),
            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }
}
