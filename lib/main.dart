import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/theme.dart';
import 'features/bottom_bar.dart';
import 'features/profile/profile_page.dart';
import 'features/match/match_page.dart';
import 'features/settings/settings_page.dart';

final router = GoRouter(
  initialLocation: '/profile',
  routes: [
    GoRoute(path: '/profile',  builder: (_, __) => BottomScaffold(child: ProfilePage(),  index: 0)),
    GoRoute(path: '/match',    builder: (_, __) => BottomScaffold(child: MatchPage(),    index: 1)),
    GoRoute(path: '/settings', builder: (_, __) => BottomScaffold(child: SettingsPage(), index: 2)),
  ],
);

void main() {
  runApp(MaterialApp.router(
    debugShowCheckedModeBanner: false,
    routerConfig: router,
    theme: AppTheme.material3(),
  ));
}
