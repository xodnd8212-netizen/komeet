import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { ko, ja }

class I18n extends InheritedWidget {
  final AppLocale locale;
  final Map<String, String> _strings;

  I18n({
    super.key,
    required this.locale,
    required Map<String, Map<String, String>> messages,
    required Widget child,
  }) : _strings = messages[_localeCode(locale)] ?? const {},
       super(child: child);

  static I18n of(BuildContext context) {
    final I18n? scope = context.dependOnInheritedWidgetOfExactType<I18n>();
    assert(scope != null, 'I18n not found in context');
    return scope!;
  }

  String t(String key) => _strings[key] ?? key;

  @override
  bool updateShouldNotify(I18n oldWidget) => oldWidget.locale != locale;

  static String _localeCode(AppLocale locale) => switch (locale) {
    AppLocale.ko => 'ko',
    AppLocale.ja => 'ja',
  };
}

const kMessages = <String, Map<String, String>>{
  'ko': {
    'app.profile': '내 프로필',
    'app.match_now': '지금 매칭',
    'app.settings': '설정',
    'settings.language': '언어',
    'settings.lang.ko': '한국어',
    'settings.lang.ja': '日本語',
    'home.title': '코밋 Komeet',
    'home.subtitle': '내 프로필을 설정하세요. (사진/소개/관심사/선호 거리)',
    'match.title': '지금 매칭',
    'match.subtitle': '위치/취향 기반 추천은 곧 연결합니다.',
    'match.label.like': '좋아요',
    'match.label.skip': '건너뛰기',
    'settings.title': '설정',
    'settings.subtitle': '알림/언어(ko/ja)/최대 거리/필터를 조정하세요.',
    'match.like': '좋아요',
    'match.skip': '건너뛰기',
    'chat.placeholder': '메시지를 입력하세요…',
    'chat.typing': '상대가 입력 중…',
    'match.empty': '추천 대기 중',
    'settings.open_chat_demo': '채팅 데모 열기',
    'settings.chat_route_hint': '라우트: /chat 로 이동하세요.',
    'settings.max_distance': '최대 거리 (km)',
    'settings.notifications': '푸시 알림',
    'settings.filter.tokyo_only': '도쿄 추천만 보기(데모)',
  },
  'ja': {
    'app.profile': 'マイプロフィール',
    'app.match_now': 'マッチング',
    'app.settings': '設定',
    'settings.language': '言語',
    'settings.lang.ko': '韓国語',
    'settings.lang.ja': '日本語',
    'home.title': 'コミート Komeet',
    'home.subtitle': 'プロフィールを設定してください。（写真・紹介・興味・距離）',
    'match.title': 'いまのマッチ',
    'match.subtitle': '位置/好みに基づくおすすめを間もなく接続します。',
    'match.label.like': 'いいね',
    'match.label.skip': 'スキップ',
    'settings.title': '設定',
    'settings.subtitle': '通知/言語(ko/ja)/距離/フィルタを調整してください。',
    'match.like': 'いいね',
    'match.skip': 'スキップ',
    'chat.placeholder': 'メッセージを入力…',
    'chat.typing': '相手が入力中…',
    'match.empty': 'おすすめを準備中',
    'settings.open_chat_demo': 'チャットデモを開く',
    'settings.chat_route_hint': 'ルート: /chat へ移動してください。',
    'settings.max_distance': '最大距離 (km)',
    'settings.notifications': 'プッシュ通知',
    'settings.filter.tokyo_only': '東京のみのおすすめ(デモ)',
  },
};

class I18nProvider extends StatefulWidget {
  final AppLocale initialLocale;
  final Map<String, Map<String, String>> messages;
  final Widget child;
  const I18nProvider({
    super.key,
    required this.initialLocale,
    required this.messages,
    required this.child,
  });

  static _I18nProviderState of(BuildContext context) {
    final _I18nProviderState? state = context
        .findAncestorStateOfType<_I18nProviderState>();
    assert(state != null, 'I18nProvider not found in context');
    return state!;
  }

  @override
  State<I18nProvider> createState() => _I18nProviderState();
}

class _I18nProviderState extends State<I18nProvider> {
  late AppLocale _locale = widget.initialLocale;
  static const _kLocaleKey = 'app.locale';

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLocaleKey);
      if (code == 'ko') {
        setState(() {
          _locale = AppLocale.ko;
        });
      } else if (code == 'ja') {
        setState(() {
          _locale = AppLocale.ja;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  void setLocale(AppLocale next) {
    if (_locale == next) return;
    setState(() {
      _locale = next;
    });
    _persist(next);
  }

  AppLocale get locale => _locale;

  Future<void> _persist(AppLocale v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, I18n._localeCode(v));
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return I18n(
      locale: _locale,
      messages: widget.messages,
      child: widget.child,
    );
  }
}
