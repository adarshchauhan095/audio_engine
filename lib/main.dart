import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

import 'ui/screens/therapy_entry_screen.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

Future<void> _configureAndroidAudioSession() async {
  if (!Platform.isAndroid) return;
  final AudioSession session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.audibilityEnforced,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ),
  );
  await session.setActive(true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAndroidAudioSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinnitX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      // Unified launcher: Phases 1–4 (+ future phases via TherapyEntryScreen).
      home: const TherapyEntryScreen(),
    );
  }
}
