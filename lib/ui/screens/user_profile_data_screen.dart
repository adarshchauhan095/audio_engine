import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../storage/user_profile_storage.dart';
import '../onboarding/user_profile_onboarding.dart';

class UserProfileDataScreen extends StatefulWidget {
  const UserProfileDataScreen({super.key});

  @override
  State<UserProfileDataScreen> createState() => _UserProfileDataScreenState();
}

class _UserProfileDataScreenState extends State<UserProfileDataScreen> {
  final UserProfileStorage _storage = UserProfileStorage();
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _profileFuture = _storage.getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Profile Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UserProfileOnboarding()),
              ).then((_) => _reload());
            },
          )
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('No profile data found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildDataRow('Tinnitus Duration', profile.tinnitusDuration),
              _buildDataRow('Onset Type', profile.tinnitusOnsetType),
              _buildDataRow('Tone Type', profile.toneType),
              _buildDataRow('Tone Stability', profile.toneStability),
              _buildDataRow('Location', profile.location),
              _buildDataRow('Frequency (Hz)', '${profile.selfReportedFrequencyHz.toStringAsFixed(1)} Hz'),
              _buildDataRow('Loudness', profile.selfReportedLoudness.toStringAsFixed(1)),
              _buildDataRow('Dominance', profile.dominance.toStringAsFixed(1)),
              _buildDataRow('Awareness', profile.awareness.toStringAsFixed(1)),
              _buildDataRow('Reactivity to Noise', profile.reactivityToNoise),
              _buildDataRow('Reactivity to Silence', profile.reactivityToSilence),
              _buildDataRow('Reactivity to Stress', profile.reactivityToStress.toStringAsFixed(1)),
              _buildDataRow('Reactivity to Fatigue', profile.reactivityToFatigue.toStringAsFixed(1)),
              _buildDataRow('Morning Intensity', profile.morningIntensity.toStringAsFixed(1)),
              _buildDataRow('Evening Intensity', profile.eveningIntensity.toStringAsFixed(1)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
