import 'package:flutter/material.dart';

import 'basic_therapy_screen.dart';
import 'modulation_therapy_screen.dart';
import 'phase3_modules_screen.dart';

/// Minimal launcher so Phase 1 and Phase 2 stay on separate screens per spec.
class TherapyEntryScreen extends StatelessWidget {
  const TherapyEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TinnitX')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Therapy',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Basic Therapy'),
              subtitle: const Text('Phase 1 — core engine only'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const BasicTherapyScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Modulation Therapy'),
              subtitle: const Text('Phase 2 — AM / FM / narrowband noise'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const ModulationTherapyScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Phase 3 Modules'),
              subtitle: const Text('RMP / PIP / Binaural'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const Phase3ModulesScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
