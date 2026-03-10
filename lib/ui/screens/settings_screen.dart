import 'package:flutter/material.dart';
import '../../session/audio_runtime_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.runtime});
  final AudioRuntimeController runtime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: runtime.stereoEnabled,
            builder: (context, isStereo, _) {
              return SwitchListTile(
                title: const Text('Enable Stereo Output'),
                subtitle: const Text('When disabled, all spatial modules will output evenly formatted dual-mono.'),
                value: isStereo,
                onChanged: runtime.setStereoEnabled,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            trailing: const Text('v1.0.0 (Milestone 5)'),
          ),
        ],
      ),
    );
  }
}
