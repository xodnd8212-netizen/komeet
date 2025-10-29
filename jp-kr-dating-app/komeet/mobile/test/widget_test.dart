import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komeet/main.dart';

void main() {
  testWidgets('ProfilePage has a title and a message', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Welcome to your profile!'), findsOneWidget);
  });

  testWidgets('MatchPage has a title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    expect(find.text('Matches'), findsOneWidget);
  });

  testWidgets('SettingsPage has a title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });
}