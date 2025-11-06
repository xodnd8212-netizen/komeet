import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/theme.dart';
import 'features/bottom_bar.dart';
import 'features/profile/profile_page.dart';
import 'features/match/match_page.dart';
import 'features/settings/settings_page.dart';
import 'i18n/i18n.dart';
import 'features/chat/chat_page.dart';

final router = GoRouter(
  initialLocation: '/profile',
  routes: [
    GoRoute(
      path: '/profile',
      builder: (_, __) => BottomScaffold(index: 0, child: ProfilePage()),
    ),
    GoRoute(
      path: '/match',
      builder: (_, __) => BottomScaffold(index: 1, child: MatchPage()),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => BottomScaffold(index: 2, child: SettingsPage()),
    ),
    GoRoute(
      path: '/chat',
      builder: (_, state) {
        final extra = state.extra;
        if (extra is ChatArgs) {
          return ChatPage(args: extra);
        }
        return const ChatPage();
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return I18nProvider(
      initialLocale: AppLocale.ko,
      messages: kMessages,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.material3(),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
