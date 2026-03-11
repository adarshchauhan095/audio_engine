import 'dart:io';

import 'package:audio_engine/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows expected surface for current platform', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // The app boots to DashboardScreen, which handles the error state internally.
    // If it's android, we'll see 'Tinnitus Therapy Hub'.
    // If it's desktop/web, the dashboard AppBar is just 'Dashboard' before showing the error.
    if (Platform.isAndroid) {
      expect(find.text('Tinnitus Therapy Hub'), findsOneWidget);
    } else {
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.textContaining('Engine Error:'), findsOneWidget);
    }
  });
}
