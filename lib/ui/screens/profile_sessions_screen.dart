import 'package:flutter/material.dart';

import '../../models/session_params.dart';
import '../../session/audio_runtime_controller.dart';
import '../../session/profile_session_catalog.dart';
import '../../storage/session_params_storage.dart';

class ProfileSessionsScreen extends StatefulWidget {
  const ProfileSessionsScreen({
    super.key,
    required this.runtime,
    required this.onOpenSavedParams,
  });

  final AudioRuntimeController runtime;
  final VoidCallback onOpenSavedParams;

  @override
  State<ProfileSessionsScreen> createState() => _ProfileSessionsScreenState();
}

class _ProfileSessionsScreenState extends State<ProfileSessionsScreen> {
  late TherapyProfile _selectedProfile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProfile = ProfileSessionCatalog.profileExamples.first;
  }

  List<SessionParams> get _templates =>
      ProfileSessionCatalog.buildTemplateSessionsForProfile(_selectedProfile);

  Future<void> _saveTemplate(
    SessionParams template, {
    required double frequencyHz,
    required double amplitude,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final SessionParams itemToSave = template.copyWith(
        id: _savedId(template.title, _selectedProfile.id),
        frequencyHz: frequencyHz,
        amplitude: amplitude,
        createdAtIso: DateTime.now().toIso8601String(),
        category: 'saved',
      );
      final bool ok = await SessionParamsStorage.save(itemToSave);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Saved ${template.title}: '
                      '${frequencyHz.toStringAsFixed(1)} Hz, '
                      'Amp ${amplitude.toStringAsFixed(2)}, '
                      '${template.durationSeconds}s'
                : 'Failed to save session parameters',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _runBatch() async {
    final bool completedAll = await widget.runtime.runProfileSessionBatch(
      _templates,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completedAll
              ? 'Completed ${_templates.length} sessions for ${_selectedProfile.name}'
              : 'Session batch ended before completion',
        ),
      ),
    );
  }

  Future<void> _runSingle(SessionParams template) async {
    final bool completed = await widget.runtime.runProfileSession(template);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? '${template.title} completed'
              : '${template.title} ended before completion',
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
          final bool anyRunning = widget.runtime.profileSessionRunning.value;
          final SessionRunSnapshot? active = widget.runtime.activeSession.value;
          final bool hasEngine = widget.runtime.hasEngine;
          final List<SessionParams> templates = _templates;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Profile session planning',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Only the active session shows running status, countdown, and live values.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<TherapyProfile>(
                          initialValue: _selectedProfile,
                          decoration: const InputDecoration(
                            labelText: 'Profile example',
                            border: OutlineInputBorder(),
                          ),
                          items: ProfileSessionCatalog.profileExamples.map((
                            TherapyProfile profile,
                          ) {
                            return DropdownMenuItem<TherapyProfile>(
                              value: profile,
                              child: Text(profile.name),
                            );
                          }).toList(),
                          onChanged: anyRunning
                              ? null
                              : (TherapyProfile? value) {
                                  if (value == null) return;
                                  setState(() => _selectedProfile = value);
                                },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedProfile.conditionSummary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: !hasEngine || anyRunning
                                  ? null
                                  : _runBatch,
                              icon: const Icon(Icons.playlist_play),
                              label: Text('Run ${templates.length} sessions'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: anyRunning ? _endRunningSession : null,
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('End running session'),
                            ),
                            OutlinedButton.icon(
                              onPressed: widget.onOpenSavedParams,
                              icon: const Icon(Icons.list),
                              label: const Text('Open saved params'),
                            ),
                          ],
                        ),
                        if (active != null) ...<Widget>[
                          const SizedBox(height: 10),
                          Text(
                            'Active: ${active.title} | '
                            'Remaining ${active.remainingSeconds}s | '
                            'Current ${widget.runtime.frequency.value.toStringAsFixed(1)} Hz / '
                            'Amp ${widget.runtime.amplitude.value.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...templates.map((SessionParams template) {
                  final bool isRunningThis = active?.sessionId == template.id;
                  final bool otherSessionRunning = anyRunning && !isRunningThis;
                  final double liveFrequency = isRunningThis
                      ? widget.runtime.frequency.value
                      : template.frequencyHz;
                  final double liveAmplitude = isRunningThis
                      ? widget.runtime.amplitude.value
                      : template.amplitude;
                  return _SessionTemplateCard(
                    template: template,
                    hasEngine: hasEngine,
                    isRunning: isRunningThis,
                    otherSessionRunning: otherSessionRunning,
                    progress: isRunningThis ? (active?.progress ?? 0.0) : 0.0,
                    remainingSeconds: isRunningThis
                        ? (active?.remainingSeconds ?? template.durationSeconds)
                        : template.durationSeconds,
                    endTimeLabel: isRunningThis
                        ? _formatTimeOnly(active?.endsAtIso)
                        : '--:--',
                    currentFrequencyHz: liveFrequency,
                    currentAmplitude: liveAmplitude,
                    onApply: () => widget.runtime.applySessionParams(template),
                    onStart: () => _runSingle(template),
                    onEnd: _endRunningSession,
                    onSave: () => _saveTemplate(
                      template,
                      frequencyHz: liveFrequency,
                      amplitude: liveAmplitude,
                    ),
                    saveDisabled: _saving,
                  );
                }),
                const SizedBox(height: 88),
              ],
            ),
          );
        },
      ),
    );
  }

  String _savedId(String title, String profileId) {
    final String normalizedTitle = title.toLowerCase().replaceAll(' ', '-');
    return 'saved-$profileId-$normalizedTitle-${DateTime.now().microsecondsSinceEpoch}';
  }
}

class _SessionTemplateCard extends StatelessWidget {
  const _SessionTemplateCard({
    required this.template,
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
    required this.onSave,
    required this.saveDisabled,
  });

  final SessionParams template;
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
  final VoidCallback onSave;
  final bool saveDisabled;

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
                    template.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(isRunning ? 'Running' : 'Idle'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Planned: ${template.frequencyHz.toStringAsFixed(1)} Hz   '
              'Amplitude: ${template.amplitude.toStringAsFixed(2)}   '
              'Duration: ${template.durationSeconds}s',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Current: ${currentFrequencyHz.toStringAsFixed(1)} Hz   '
              'Amplitude: ${currentAmplitude.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (template.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                template.notes,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
                FilledButton.tonal(
                  onPressed: saveDisabled ? null : onSave,
                  child: const Text('Save current values'),
                ),
              ],
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
