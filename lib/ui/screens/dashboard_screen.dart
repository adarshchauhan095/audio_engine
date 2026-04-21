import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../session/audio_runtime_controller.dart';
import 'audio_control_screen.dart';
import 'debug_tests_screen.dart';
import 'module_demo_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'therapy_session_screen.dart';
import 'tinnitus_detection_screen.dart';
import 'ams_matching_screen.dart';
import 'hearing_threshold_check_screen.dart';
import 'premium_features_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AudioRuntimeController _runtime;

  @override
  void initState() {
    super.initState();
    _runtime = AudioRuntimeController();
    _runtime.attachRouteRecoveryChannel(
      ServicesBinding.instance.defaultBinaryMessenger,
    );
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  void _pushScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _runtime.error,
      builder: (context, error, _) {
        if (error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: Center(child: Text('Engine Error: $error', style: const TextStyle(color: Colors.red))),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('TinnitX'),
          ),
          body: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _ModuleCard(
                title: 'Tinnitus Detection',
                icon: Icons.hearing,
                onTap: () => _pushScreen(context, TinnitusDetectionScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'AMS Matching',
                icon: Icons.graphic_eq,
                onTap: () => _pushScreen(context, AmsMatchingScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'Hearing Profile Check',
                icon: Icons.hearing,
                onTap: () => _pushScreen(
                  context,
                  HearingThresholdCheckScreen(runtime: _runtime),
                ),
              ),
              _ModuleCard(
                title: 'Sound Support Session',
                icon: Icons.surround_sound,
                onTap: () => _pushScreen(context, TherapySessionScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'My Profile',
                icon: Icons.person,
                onTap: () => _pushScreen(context, ProfileScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'Audio Controls',
                icon: Icons.tune,
                onTap: () => _pushScreen(context, AudioControlScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'Debug Tests',
                icon: Icons.bug_report,
                onTap: () => _pushScreen(context, DebugTestsScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'Module Demo',
                icon: Icons.science,
                onTap: () => _pushScreen(context, ModuleDemoScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'Premium Features',
                icon: Icons.star,
                onTap: () => _pushScreen(context, PremiumFeaturesScreen(runtime: _runtime)),
              ),
              _ModuleCard(
                title: 'Settings',
                icon: Icons.settings,
                onTap: () => _pushScreen(context, SettingsScreen(runtime: _runtime)),
              ),
            ],
          ),
          floatingActionButton: ValueListenableBuilder<bool>(
            valueListenable: _runtime.playing,
            builder: (context, isPlaying, _) {
              return FloatingActionButton.extended(
                onPressed: _runtime.hasEngine ? _runtime.togglePlay : null,
                label: Text(isPlaying ? 'Stop Engine' : 'Start Engine'),
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                backgroundColor: isPlaying ? Colors.red : Theme.of(context).primaryColor,
              );
            },
          ),
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
