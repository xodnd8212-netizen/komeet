// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:komeet/theme/theme.dart';
import 'package:komeet/i18n/i18n.dart';
import 'package:komeet/features/onboarding/onboarding_page.dart';

void main() {
  testWidgets('MyApp renders without errors', (WidgetTester tester) async {
    // 테스트용 router 생성 (redirect 없이)
    final testRouter = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingPage(),
        ),
      ],
    );

    // 테스트용 MyApp 위젯 생성
    final testApp = I18nProvider(
      initialLocale: AppLocale.ko,
      messages: kMessages,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: testRouter,
        theme: AppTheme.material3(),
      ),
    );

    await tester.pumpWidget(testApp);
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
