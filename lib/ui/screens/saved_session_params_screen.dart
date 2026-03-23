import 'package:flutter/material.dart';

import '../../models/session_params.dart';
import '../../session/audio_runtime_controller.dart';
import '../../storage/session_params_storage.dart';

class SavedSessionParamsScreen extends StatefulWidget {
  const SavedSessionParamsScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  State<SavedSessionParamsScreen> createState() =>
      _SavedSessionParamsScreenState();
}

class _SavedSessionParamsScreenState extends State<SavedSessionParamsScreen> {
  bool _loading = true;
  List<SessionParams> _savedItems = <SessionParams>[];

  @override
  void initState() {
    super.initState();
    widget.runtime.prepareForProfileSessionsWorkspace();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final List<SessionParams> items = await SessionParamsStorage.loadAll();
    if (!mounted) return;
    setState(() {
      _savedItems = items;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    await SessionParamsStorage.deleteById(id);
    await _reload();
  }

  Future<void> _runSingle(SessionParams item) async {
    final bool completed = await widget.runtime.runProfileSession(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? '${item.title} completed'
              : '${item.title} ended before completion',
        ),
      ),
    );
  }

  void _endRunningSession() {
    widget.runtime.endRunningSession();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Running session ended')));
  }

  @override
  Widget build(BuildContext context) {
    final Listenable rebuildSessionState = Listenable.merge(<Listenable>[
      widget.runtime.profileSessionRunning,
      widget.runtime.activeSession,
      widget.runtime.frequency,
      widget.runtime.amplitude,
    ]);

    return SafeArea(
      child: AnimatedBuilder(
        animation: rebuildSessionState,
        builder: (BuildContext context, Widget? child) {
          final SessionRunSnapshot? active = widget.runtime.activeSession.value;
          final bool anyRunning = widget.runtime.profileSessionRunning.value;
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Saved session params',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              if (active != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Active: ${active.title} | Remaining ${active.remainingSeconds}s',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _endRunningSession,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('End'),
                      ),
                    ],
                  ),
                ),
              if (_loading) const LinearProgressIndicator(minHeight: 3),
              Expanded(
                child: _savedItems.isEmpty
                    ? _EmptyState(onReload: _reload)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: _savedItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          final SessionParams item = _savedItems[index];
                          final bool isRunningThis =
                              active?.sessionId == item.id;
                          final bool otherSessionRunning =
                              anyRunning && !isRunningThis;
                          final double liveFrequency = isRunningThis
                              ? widget.runtime.frequency.value
                              : item.frequencyHz;
                          final double liveAmplitude = isRunningThis
                              ? widget.runtime.amplitude.value
                              : item.amplitude;
                          return _SavedSessionCard(
                            item: item,
                            hasEngine: widget.runtime.hasEngine,
                            isRunning: isRunningThis,
                            otherSessionRunning: otherSessionRunning,
                            progress: isRunningThis
                                ? (active?.progress ?? 0.0)
                                : 0.0,
                            remainingSeconds: isRunningThis
                                ? (active?.remainingSeconds ??
                                      item.durationSeconds)
                                : item.durationSeconds,
                            endTimeLabel: isRunningThis
                                ? _formatTimeOnly(active?.endsAtIso)
                                : '--:--',
                            currentFrequencyHz: liveFrequency,
                            currentAmplitude: liveAmplitude,
                            onApply: () =>
                                widget.runtime.applySessionParams(item),
                            onStart: () => _runSingle(item),
                            onEnd: _endRunningSession,
                            onDelete: () => _delete(item.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedSessionCard extends StatelessWidget {
  const _SavedSessionCard({
    required this.item,
    required this.hasEngine,
    required this.isRunning,
    required this.otherSessionRunning,
    required this.progress,
    required this.remainingSeconds,
    required this.endTimeLabel,
    required this.currentFrequencyHz,
    required this.currentAmplitude,
    required this.onApply,
    required this.onStart,
    required this.onEnd,
    required this.onDelete,
  });

  final SessionParams item;
  final bool hasEngine;
  final bool isRunning;
  final bool otherSessionRunning;
  final double progress;
  final int remainingSeconds;
  final String endTimeLabel;
  final double currentFrequencyHz;
  final double currentAmplitude;
  final VoidCallback onApply;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                ),
              ],
            ),
            Text(
              '${item.profileName} (${item.profileId})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Frequency: ${item.frequencyHz.toStringAsFixed(1)} Hz   '
              'Amplitude: ${item.amplitude.toStringAsFixed(2)}   '
              'Duration: ${item.durationSeconds}s',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Current: ${currentFrequencyHz.toStringAsFixed(1)} Hz   '
              'Amplitude: ${currentAmplitude.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Saved at: ${_formatDate(item.createdAtIso)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (item.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(item.notes, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (isRunning) ...<Widget>[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text(
                'Ends at $endTimeLabel | Remaining ${remainingSeconds}s',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: hasEngine && !otherSessionRunning ? onApply : null,
                  child: const Text('Apply params'),
                ),
                if (isRunning)
                  FilledButton.icon(
                    onPressed: onEnd,
                    icon: const Icon(Icons.stop),
                    label: const Text('End session'),
                  )
                else
                  FilledButton.icon(
                    onPressed: hasEngine && !otherSessionRunning
                        ? onStart
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start session'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final DateTime value = DateTime.parse(iso).toLocal();
      final String mm = value.month.toString().padLeft(2, '0');
      final String dd = value.day.toString().padLeft(2, '0');
      final String hh = value.hour.toString().padLeft(2, '0');
      final String min = value.minute.toString().padLeft(2, '0');
      return '${value.year}-$mm-$dd $hh:$min';
    } catch (_) {
      return iso;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.folder_open_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text(
              'No saved session parameters yet.\n'
              'Save from the Profile Sessions screen.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimeOnly(String? iso) {
  if (iso == null || iso.isEmpty) return '--:--';
  try {
    final DateTime dt = DateTime.parse(iso).toLocal();
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    final String ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  } catch (_) {
    return '--:--';
  }
}
