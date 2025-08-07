// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:community_beat/main_app.dart';

void main() {
  testWidgets('Community Beat app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CommunityBeatApp());

    // Verify that the app loads with the News & Events screen
    expect(find.text('News & Events'), findsOneWidget);
    
    // Verify that bottom navigation is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
