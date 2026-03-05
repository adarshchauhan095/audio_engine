import 'package:flutter/material.dart';

import '../session/audio_runtime_controller.dart';
import 'screens/audio_control_screen.dart';
import 'screens/debug_tests_screen.dart';
import 'screens/patient_sessions_screen.dart';
import 'screens/saved_session_params_screen.dart';
import 'screens/tinnitus_detection_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AudioRuntimeController _runtime;
  int _index = 0;

  static const List<String> _titles = <String>[
    'Audio Controls',
    'Tinnitus Detection',
    'Debug Tests',
    'Patient Sessions',
    'Saved Params',
  ];

  @override
  void initState() {
    super.initState();
    _runtime = AudioRuntimeController();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _runtime.error,
      builder: (BuildContext context, String? error, Widget? child) {
        if (error != null) {
          return _buildErrorWidget(context, error);
        }

        final List<Widget> pages = <Widget>[
          AudioControlScreen(runtime: _runtime),
          TinnitusDetectionScreen(runtime: _runtime),
          DebugTestsScreen(runtime: _runtime),
          PatientSessionsScreen(
            runtime: _runtime,
            onOpenSavedParams: () {
              setState(() => _index = 4);
            },
          ),
          SavedSessionParamsScreen(runtime: _runtime),
        ];
        final bool isSessionPage = _index == 3 || _index == 4;

        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_index]),
            actions: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: _runtime.playing,
                builder: (BuildContext context, bool playing, Widget? child) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        playing ? 'Playing' : 'Stopped',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (int value) {
              setState(() => _index = value);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.tune), label: 'Controls'),
              NavigationDestination(
                icon: Icon(Icons.hearing),
                label: 'Detection',
              ),
              NavigationDestination(
                icon: Icon(Icons.bug_report),
                label: 'Debug',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment),
                label: 'Sessions',
              ),
              NavigationDestination(icon: Icon(Icons.save), label: 'Saved'),
            ],
          ),
          floatingActionButton: isSessionPage
              ? null
              : ValueListenableBuilder<bool>(
                  valueListenable: _runtime.playing,
                  builder:
                      (BuildContext context, bool isPlaying, Widget? child) {
                        return FloatingActionButton.extended(
                          onPressed: _runtime.hasEngine
                              ? _runtime.togglePlay
                              : null,
                          label: Text(isPlaying ? 'Stop' : 'Play'),
                          icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                          backgroundColor: isPlaying
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).primaryColor,
                        );
                      },
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error:',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
