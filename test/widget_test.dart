import 'dart:io';

import 'package:audio_engine/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows expected surface for current platform', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    if (Platform.isAndroid) {
      expect(find.text('Play'), findsOneWidget);
    } else {
      expect(find.text('Error:'), findsOneWidget);
      expect(find.text('Native audio only on Android'), findsOneWidget);
    }
  });
}
