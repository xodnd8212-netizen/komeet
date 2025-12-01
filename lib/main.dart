import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/theme.dart';
import 'features/bottom_bar.dart';
import 'features/profile/profile_page.dart';
import 'features/match/match_page.dart';
import 'features/settings/settings_page.dart';
import 'features/settings/policy_page.dart';
import 'features/store/coin_store_page.dart';
import 'i18n/i18n.dart';
import 'features/chat/chat_page.dart';
import 'features/chat/chat_list_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'services/notifications.dart';
import 'services/push_notifications.dart';
import 'services/auth_service.dart';
import 'services/prefs.dart';
import 'services/offline_service.dart';
import 'features/auth/login_page.dart';
import 'features/admin/admin_login_page.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'features/notifications/likes_notification_page.dart';
import 'services/admin_service.dart';
import 'utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

final router = GoRouter(
  initialLocation: '/onboarding',
  redirect: (context, state) async {
    final isLoggedIn = AuthService.currentUser != null;
    final isOnboardingPage = state.matchedLocation == '/onboarding';
    final isLoginPage = state.matchedLocation == '/login';
    final isAdminLoginPage = state.matchedLocation == '/admin/login';
    final isAdminPage = state.matchedLocation.startsWith('/admin');

    // 어드민 페이지 접근 시 (로그인만 확인, 어드민 여부는 페이지에서 확인)
    if (isAdminPage && !isLoggedIn && !isAdminLoginPage) {
      return '/login';
    }

    // 온보딩 완료 여부 확인
    final onboardingCompleted = await PrefsService.getOnboardingCompleted();

    // 온보딩 미완료 시 온보딩 페이지로 (어드민 페이지 제외)
    if (!onboardingCompleted && !isOnboardingPage && !isAdminPage) {
      return '/onboarding';
    }

    // 로그인 상태 확인 (어드민 페이지 제외)
    if (!isLoggedIn && !isLoginPage && !isOnboardingPage && !isAdminLoginPage) {
      return '/login';
    }
    if (isLoggedIn && isLoginPage && !isAdminPage) {
      // 일반 로그인 시 어드민 여부 확인
      final isAdmin = await AdminService.isAdmin();
      if (isAdmin) {
        return '/admin';
      }
      return '/profile';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(
      path: '/profile',
      builder: (_, __) => BottomScaffold(index: 0, child: ProfilePage()),
    ),
    GoRoute(
      path: '/match',
      builder: (_, __) => BottomScaffold(index: 1, child: MatchPage()),
    ),
    GoRoute(
      path: '/chat-list',
      builder: (_, __) => BottomScaffold(index: 2, child: ChatListPage()),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => BottomScaffold(index: 3, child: SettingsPage()),
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
    GoRoute(
      path: '/policy/:id',
      builder: (_, state) {
        final policyId = state.pathParameters['id'] ?? '';
        return PolicyPage(policyId: policyId);
      },
    ),
    GoRoute(path: '/coin-store', builder: (_, __) => const CoinStorePage()),
    GoRoute(path: '/chat-list', builder: (_, __) => const ChatListPage()),
    GoRoute(path: '/likes', builder: (_, __) => const LikesNotificationPage()),
    GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginPage()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardPage()),
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    AppLogger.info('Firebase 초기화 완료');

    // 오프라인 지속성 활성화
    await OfflineService.enablePersistence();

    // FCM 초기화 (Firebase 초기화 후)
    await PushNotificationService.init();

    // 로그인 상태 변경 시 FCM 토큰 저장
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        // 로그인 시 FCM 토큰 다시 저장
        await PushNotificationService.saveTokenIfLoggedIn();
      }
    });
  } catch (e) {
    // Firebase 설정 파일이 없을 수 있음
    // 개발 중에는 계속 진행, 프로덕션에서는 에러 처리 필요
    debugPrint('Firebase 초기화 오류: $e');
    debugPrint('Firebase 설정 파일을 확인하세요. (FIREBASE_SETUP.md 참고)');
  }

  await NotificationService.init();

  runApp(const MyApp());
}
