// F0.4 spike screen smoke test — renders the scaffold without crashing.
// Full EXIF behavior is verified manually on real devices, not in widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/main.dart';

void main() {
  testWidgets('EXIF spike screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ExifSpikeApp());

    expect(find.text('F0.4 — EXIF spike (photo_manager)'), findsOneWidget);
    expect(find.text('Load recent photos'), findsOneWidget);
    expect(find.byIcon(Icons.photo_library), findsOneWidget);
  });
}
