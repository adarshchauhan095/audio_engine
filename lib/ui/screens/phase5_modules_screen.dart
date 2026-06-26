import 'package:flutter/material.dart';
import '../../session/audio_runtime_controller.dart';

class Phase5ModulesScreen extends StatefulWidget {
  final AudioRuntimeController runtimeController;

  const Phase5ModulesScreen({super.key, required this.runtimeController});

  @override
  State<Phase5ModulesScreen> createState() => _Phase5ModulesScreenState();
}

class _Phase5ModulesScreenState extends State<Phase5ModulesScreen> {
  int _activeGenerator = 0;

  void _setGenerator(int id, String name, double p1, double p2, double p3, double p4, double p5) {
    widget.runtimeController.setPhase52GeneratorParams(id, p1, p2, p3, p4, p5);
    setState(() {
      _activeGenerator = id;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activated: $name')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phase 5 Modules')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Advanced DSP Generators',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Select an advanced module to apply targeted DSP therapy.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          _buildGeneratorTile(
            id: 1,
            title: 'PhaseBreaker',
            subtitle: 'Advanced phase modulation',
            onTap: () => _setGenerator(1, 'PhaseBreaker', 400.0, 0.5, 0.5, 0.5, 1.0),
          ),
          const SizedBox(height: 8),
          _buildGeneratorTile(
            id: 2,
            title: 'AntiCorrelation',
            subtitle: 'Dynamic phase inversion',
            onTap: () => _setGenerator(2, 'AntiCorrelation', 400.0, 0.5, 10.0, 1.0, 0.0),
          ),
          const SizedBox(height: 8),
          _buildGeneratorTile(
            id: 3,
            title: 'ContrastRemap',
            subtitle: 'Frequency contrast enhancement',
            onTap: () => _setGenerator(3, 'ContrastRemap', 400.0, 0.5, 0.5, 0.5, 1.0),
          ),
          const SizedBox(height: 8),
          _buildGeneratorTile(
            id: 4,
            title: 'SalienceScrambler',
            subtitle: 'Stochastic burst scrambling',
            onTap: () => _setGenerator(4, 'SalienceScrambler', 10.0, 50.0, 0.5, 1.0, 0.0),
          ),
          const SizedBox(height: 8),
          _buildGeneratorTile(
            id: 5,
            title: 'NullModel',
            subtitle: 'Baseline noise floor',
            onTap: () => _setGenerator(5, 'NullModel', 0.0, 0.0, 0.0, 0.0, 1.0),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.redAccent, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: const Text('Disable All Modules', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.power_settings_new, color: Colors.redAccent),
              onTap: () => _setGenerator(0, 'Disabled', 0.0, 0.0, 0.0, 0.0, 0.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorTile({required int id, required String title, required String subtitle, required VoidCallback onTap}) {
    final isActive = _activeGenerator == id;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: isActive ? 2 : 0,
      color: isActive ? colorScheme.primaryContainer : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isActive ? colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: isActive 
            ? Icon(Icons.check_circle, color: colorScheme.primary) 
            : const Icon(Icons.play_circle_outline),
        onTap: onTap,
      ),
    );
  }
}
