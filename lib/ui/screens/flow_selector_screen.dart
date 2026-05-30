import 'package:flutter/material.dart';

import '../../session/flow/flow_catalog.dart';
import '../../session/flow/flow_definition.dart';
import 'flow_live_screen.dart';

/// Phase 4 — pick a predefined flow and start execution.
class FlowSelectorScreen extends StatelessWidget {
  const FlowSelectorScreen({super.key});

  String _formatDuration(int totalSeconds) {
    final int mins = totalSeconds ~/ 60;
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flow Engine')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Select a flow',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...FlowCatalog.predefined.map((FlowDefinition flow) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        flow.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${flow.stepCount} steps · '
                        '${_formatDuration(flow.totalDurationSeconds)} total',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => FlowLiveScreen(flow: flow),
                            ),
                          );
                        },
                        child: const Text('Start Flow'),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed: null,
                        child: const Text('Edit Flow (Phase 5)'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
