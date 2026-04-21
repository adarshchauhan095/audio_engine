import 'package:flutter/material.dart';

import '../../models/tinnitx_user_profile.dart';
import '../../models/edge_detection_result.dart';
import '../../session/audio_runtime_controller.dart';
import '../../session/profile_session_catalog.dart';
import '../../storage/detected_frequency_storage.dart';
import '../../storage/edge_detection_storage.dart';
import '../../storage/tinnitx_user_profile_storage.dart';
import '../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.runtime});
  final AudioRuntimeController runtime;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  static const String _userId = 'local_user';

  late Future<TinnitXUserProfile> _profileFuture;
  late Future<double?> _detectedFrequencyFuture;
  late Future<EdgeDetectionResult?> _edgeDetectionFuture;

  TinnitXUserProfile? _profile;
  bool _profileSaving = false;

  // Required fields (editable)
  double _tinnitusLoudness = 5.0;
  TinnitusCharacter _tinnitusCharacter = TinnitusCharacter.tonal;
  Laterality _laterality = Laterality.unsure;

  // Optional modifiers (Phase 2-ready, user-driven)
  final TextEditingController _ageController = TextEditingController();
  SubjectiveHearingProfile? _subjectiveHearingProfile;
  SoundSensitivity? _soundSensitivity;
  final TextEditingController _stressLevelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  void _reloadAll() {
    _profileFuture = _loadProfile();
    _detectedFrequencyFuture = DetectedFrequencyStorage.loadDetectedFrequency();
    _edgeDetectionFuture = EdgeDetectionStorage.loadResult();
    if (mounted) setState(() {});
  }

  @override
  void didPopNext() {
    // Coming back to this screen: refresh saved HPE/AMS results.
    _reloadAll();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _ageController.dispose();
    _stressLevelController.dispose();
    super.dispose();
  }

  Future<TinnitXUserProfile> _loadProfile() async {
    await TinnitXUserProfileStorage.migrateLegacyIfNeeded(userId: _userId);
    final TinnitXUserProfile p =
        await TinnitXUserProfileStorage.getOrCreateMinimal(userId: _userId);
    _applyProfileToForm(p);
    return p;
  }

  void _applyProfileToForm(TinnitXUserProfile p) {
    _profile = p;
    _tinnitusLoudness = p.tinnitusLoudness;
    _tinnitusCharacter = p.tinnitusCharacter;
    _laterality = p.laterality;

    _ageController.text = p.age?.toStringAsFixed(0) ?? '';
    _subjectiveHearingProfile = p.subjectiveHearingProfile;
    _soundSensitivity = p.soundSensitivity;
    _stressLevelController.text = p.stressLevel?.toString() ?? '';
    if (mounted) setState(() {});
  }

  double? _tryParseDouble(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  Future<void> _saveProfileEdits() async {
    if (_profileSaving) return;
    final p = _profile;
    if (p == null) return;

    setState(() => _profileSaving = true);
    try {
      final double? age = _tryParseDouble(_ageController.text);
      final double? stress = _tryParseDouble(_stressLevelController.text);

      final updated = p.copyWith(
        tinnitusLoudness: _tinnitusLoudness,
        tinnitusCharacter: _tinnitusCharacter,
        laterality: _laterality,
        age: age,
        subjectiveHearingProfile: _subjectiveHearingProfile,
        soundSensitivity: _soundSensitivity,
        stressLevel: stress,
      );

      await TinnitXUserProfileStorage.saveProfile(updated);
      _applyProfileToForm(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Progress'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _reloadAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Saved Matching Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<double?>(
                      future: _detectedFrequencyFuture,
                      builder: (context, snap) {
                        final v = snap.data;
                        final String text = v == null
                            ? 'Detected frequency (local): —'
                            : 'Detected frequency (local): ${v.toStringAsFixed(1)} Hz';
                        return Text(text);
                      },
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<EdgeDetectionResult?>(
                      future: _edgeDetectionFuture,
                      builder: (context, snap) {
                        final r = snap.data;
                        if (r == null) {
                          return const Text('Hearing Profile Check: —');
                        }
                        final zone = r.edgeZoneFinal;
                        return Text(
                          'Hearing Profile Check range: '
                          '${zone.lowHz.toStringAsFixed(0)}–${zone.highHz.toStringAsFixed(0)} Hz',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<TinnitXUserProfile>(
              future: _profileFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading profile...'),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Profile load failed: ${snap.error}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final p = snap.data;
                if (p != null && _profile == null) {
                  // Ensure form fields are initialized even if build occurs
                  // before initState's async work finishes.
                  _applyProfileToForm(p);
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'TinnitX Profile',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'These settings describe your sound profile and are used to personalize stimulus suggestions.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'tinnitus_frequency: ${(_profile?.tinnitusFrequency ?? 0).toStringAsFixed(1)} Hz',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'tinnitus_loudness: ${_tinnitusLoudness.toStringAsFixed(1)}',
                        ),
                        Slider(
                          value: _tinnitusLoudness.clamp(0.0, 10.0),
                          min: 0.0,
                          max: 10.0,
                          divisions: 100,
                          onChanged: (v) => setState(() => _tinnitusLoudness = v),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TinnitusCharacter>(
                          value: _tinnitusCharacter,
                          decoration:
                              const InputDecoration(labelText: 'tinnitus_character'),
                          items: TinnitusCharacter.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v.value),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _tinnitusCharacter = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Laterality>(
                          value: _laterality,
                          decoration:
                              const InputDecoration(labelText: 'laterality'),
                          items: Laterality.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v.value),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _laterality = v);
                          },
                        ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Optional modifiers'),
                          children: [
                            TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'age (years)',
                                hintText: 'Optional',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<SubjectiveHearingProfile?>(
                              value: _subjectiveHearingProfile,
                              decoration: const InputDecoration(
                                labelText: 'subjective_hearing_profile',
                              ),
                              items: <DropdownMenuItem<SubjectiveHearingProfile?>>[
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('null'),
                                ),
                                ...SubjectiveHearingProfile.values.map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.value),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _subjectiveHearingProfile = v),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<SoundSensitivity?>(
                              value: _soundSensitivity,
                              decoration: const InputDecoration(
                                labelText: 'sound_sensitivity',
                              ),
                              items: <DropdownMenuItem<SoundSensitivity?>>[
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('null'),
                                ),
                                ...SoundSensitivity.values.map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.value),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _soundSensitivity = v),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _stressLevelController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'stress_level (0–10)',
                                hintText: 'Optional',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _profileSaving ? null : _saveProfileEdits,
                          icon: _profileSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_profileSaving ? 'Saving...' : 'Save profile'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Progress Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Support Adherence', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<int>(
                      valueListenable: widget.runtime.therapySession!.totalTherapySeconds,
                      builder: (context, seconds, _) {
                        final double progress = (seconds / 3600).clamp(0.0, 1.0);
                        return Column(
                          children: [
                            CircularProgressIndicator(value: progress, strokeWidth: 8),
                            const SizedBox(height: 16),
                            Text('${(progress * 100).toStringAsFixed(1)}% Complete for this week (${seconds}s / 3600s).'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Live Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Live Tune Parameters', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<double>(
                      valueListenable: widget.runtime.frequency,
                      builder: (context, freq, _) {
                        return Column(
                          children: [
                            Text('Frequency: ${freq.toStringAsFixed(1)} Hz'),
                            Slider(
                              value: freq.clamp(
                                AudioRuntimeController.freqMin,
                                AudioRuntimeController.freqMax,
                              ),
                              min: AudioRuntimeController.freqMin,
                              max: AudioRuntimeController.freqMax,
                              onChanged: widget.runtime.setFrequency,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<double>(
                      valueListenable: widget.runtime.amplitude,
                      builder: (context, amp, _) {
                        return Column(
                          children: [
                            Text('Master Volume: ${(amp * 100).toStringAsFixed(0)}%'),
                            Slider(
                              value: amp,
                              min: 0.0,
                              max: 1.0,
                              onChanged: widget.runtime.setAmplitude,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Active Session Progress
            ValueListenableBuilder<bool>(
              valueListenable: widget.runtime.therapySession!.isRunning,
              builder: (context, running, child) {
                if (!running) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Active Session', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<int>(
                            valueListenable: widget.runtime.therapySession!.remainingSeconds,
                            builder: (context, remain, _) {
                              final total = widget.runtime.therapySession!.warmupDuration + widget.runtime.therapySession!.mainDuration + widget.runtime.therapySession!.cooldownDuration;
                              final elapsed = total - remain;
                              final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LinearProgressIndicator(value: progress, minHeight: 8),
                                  const SizedBox(height: 8),
                                  Text('Remaining: ${remain ~/ 60}:${(remain % 60).toString().padLeft(2, '0')}', textAlign: TextAlign.right, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: widget.runtime.therapySession!.stopSession,
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Stop Session'),
                                  )
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Saved / Interested Sessions
            Text('Saved Presets', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: TherapyProfilePreset.presets.length,
              itemBuilder: (context, index) {
                final preset = TherapyProfilePreset.presets[index];
                return ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(preset.name),
                  subtitle: Text('Subthreshold: ${preset.subthreshold}, Binaural: ${preset.binaural}'),
                  trailing: const Icon(Icons.play_circle_fill),
                  onTap: () {
                    final session = widget.runtime.therapySession;
                    if (session != null) {
                        final baseFreq = preset.baseFreq ?? widget.runtime.frequency.value;
                        final baseAmp = preset.baseAmp ?? widget.runtime.amplitude.value;
                        if (preset.baseFreq != null) widget.runtime.setFrequency(preset.baseFreq!);
                        if (preset.baseAmp != null) widget.runtime.setAmplitude(preset.baseAmp!);
                        session.startSession(
                          subthreshold: preset.subthreshold,
                          rmp: preset.rmp,
                          pip: preset.pip,
                          sidebands: preset.sidebands,
                          binaural: preset.binaural,
                          baseFreq: baseFreq,
                          baseAmp: baseAmp,
                          maxIntensity: 0.5,
                          durationMinutes: 5,
                          targetRmpDepth: preset.rmpDepth ?? 0.1,
                          targetRmpRate: preset.rmpRate ?? 5.0,
                          targetPipInterval: preset.pipInterval ?? 0.2,
                          targetPipDuration: preset.pipDuration ?? 0.02,
                          targetSidebandOffset: preset.sidebandOffset ?? 100.0,
                          targetSidebandIntensity: preset.sidebandIntensity ?? 0.33,
                          targetBinauralOffset: preset.binauralOffset ?? 5.0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Started session: ${preset.name}')),
                        );
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
