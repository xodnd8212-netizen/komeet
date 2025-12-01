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
    required super.child,
  }) : _strings = messages[_localeCode(locale)] ?? const {};

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
    'app.chat': '채팅',
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
    'settings.age_badge': '19+ 성인 전용 서비스',
    'match.like': '좋아요',
    'match.skip': '건너뛰기',
    'chat.title': '채팅',
    'chat.empty': '채팅방이 없습니다',
    'chat.placeholder': '메시지를 입력하세요…',
    'chat.typing': '상대가 입력 중…',
    'match.empty': '추천 대기 중',
    'settings.open_chat_demo': '채팅 데모 열기',
    'settings.policy_title': '정책 및 가이드',
    'coin.store_title': '코인 상점',
    'coin.balance_title': '내 코인 잔액',
    'coin.free_swipes': '무료 스와이프: {count}회',
    'coin.bundle_section': '코인 번들',
    'coin.bundle_detail': '{coins}코인 · {price}원',
    'coin.bundle_bonus': '첫 구매 보너스 +{bonus}',
    'coin.purchase_button': '구매하기',
    'coin.purchase_success': '코인 {coins}개가 충전되었습니다.',
    'coin.purchase_failed': '결제 검증에 실패했습니다.',
    'coin.spend_section': '코인 사용',
    'coin.spend_success': '코인 사용이 완료되었습니다.',
    'coin.spend_failed': '코인 사용에 실패했습니다.',
    'coin.enter_receipt': '결제 영수증 입력',
    'coin.receipt_token': '영수증 토큰/ID',
    'coin.cost_label': '{coins} 코인 필요',
    'coin.action.swipe_extra': '추가 스와이프',
    'coin.action.special_like': '스페셜 좋아요',
    'coin.action.super_like': '슈퍼라이크',
    'coin.action.boost': '프로필 부스트',
    'coin.action.priority': '매칭 우선권',
    'coin.info_title': '안내',
    'coin.info_desc': '결제가 실제로 완료된 경우에만 영수증을 입력해 주세요. 모든 구매는 서버에서 검증 후 반영됩니다.',
    'common.cancel': '취소',
    'common.confirm': '확인',
    'settings.chat_route_hint': '라우트: /chat 로 이동하세요.',
    'settings.max_distance': '최대 거리 (km)',
    'settings.notifications': '푸시 알림',
    'settings.filter.tokyo_only': '도쿄 추천만 보기(데모)',
    'settings.clear_cache': '이미지 캐시 비우기',
    'settings.cache_cleared': '캐시가 삭제되었습니다',
    'settings.reset_onboarding': '온보딩 다시 보기',
    'login.subtitle': 'Korea × Japan, 새로운 만남의 시작',
    'login.age_notice': '본 서비스는 만 19세 이상만 이용 가능합니다.',
    'login.email': '이메일',
    'login.password': '비밀번호',
    'login.signin': '로그인',
    'login.signup': '회원가입',
    'login.have_account': '이미 계정이 있으신가요? 로그인',
    'login.no_account': '계정이 없으신가요? 회원가입',
    'login.or': '또는',
    'login.policies_prompt': '가입 전 커뮤니티 가이드와 정책을 확인해주세요.',
    'login.social.apple': 'Apple로 계속하기',
    'login.social.google': 'Google 계정으로 계속하기',
    'login.social.kakao': '카카오톡으로 계속하기',
    'login.social.naver': '네이버로 계속하기',
    'login.email_required': '이메일을 입력하세요',
    'login.email_invalid': '올바른 이메일 형식이 아닙니다',
    'login.password_required': '비밀번호를 입력하세요',
    'login.password_min': '비밀번호는 6자 이상이어야 합니다',
    'onboarding.skip': '건너뛰기',
    'onboarding.next': '다음',
    'onboarding.start': '시작하기',
    'policy.community': '커뮤니티 가이드',
    'policy.terms': '이용약관',
    'policy.privacy': '개인정보처리방침',
  },
  'ja': {
    'app.profile': 'マイプロフィール',
    'app.match_now': 'マッチング',
    'app.chat': 'チャット',
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
    'settings.age_badge': '19歳以上専用サービス',
    'match.like': 'いいね',
    'match.skip': 'スキップ',
    'chat.title': 'チャット',
    'chat.empty': 'チャットルームがありません',
    'chat.placeholder': 'メッセージを入力…',
    'chat.typing': '相手が入力中…',
    'match.empty': 'おすすめを準備中',
    'settings.open_chat_demo': 'チャットデモを開く',
    'settings.policy_title': 'ポリシーとガイド',
    'coin.store_title': 'コインストア',
    'coin.balance_title': 'コイン残高',
    'coin.free_swipes': '無料スワイプ: {count}回',
    'coin.bundle_section': 'コインパック',
    'coin.bundle_detail': '{coins}コイン · {price}円',
    'coin.bundle_bonus': '初回ボーナス +{bonus}',
    'coin.purchase_button': '購入する',
    'coin.purchase_success': '{coins}コインがチャージされました。',
    'coin.purchase_failed': '決済の検証に失敗しました。',
    'coin.spend_section': 'コインの使用',
    'coin.spend_success': 'コインの使用が完了しました。',
    'coin.spend_failed': 'コインの使用に失敗しました。',
    'coin.enter_receipt': '決済レシートを入力',
    'coin.receipt_token': 'レシートトークン/ID',
    'coin.cost_label': '{coins} コインが必要です',
    'coin.action.swipe_extra': '追加スワイプ',
    'coin.action.special_like': 'スペシャルいいね',
    'coin.action.super_like': 'スーパーライク',
    'coin.action.boost': 'プロフィールブースト',
    'coin.action.priority': 'マッチ優先権',
    'coin.info_title': 'ご案内',
    'coin.info_desc': '決済が完了した場合のみレシートを入力してください。すべての購入はサーバー検証後に反映されます。',
    'common.cancel': 'キャンセル',
    'common.confirm': '確認',
    'settings.chat_route_hint': 'ルート: /chat へ移動してください。',
    'settings.max_distance': '最大距離 (km)',
    'settings.notifications': 'プッシュ通知',
    'settings.filter.tokyo_only': '東京のみのおすすめ(デモ)',
    'settings.clear_cache': '画像キャッシュを削除',
    'settings.cache_cleared': 'キャッシュを削除しました',
    'settings.reset_onboarding': 'オンボーディングをやり直す',
    'login.subtitle': 'Korea × Japan、新しい出会いのスタート',
    'login.age_notice': '本サービスは19歳以上のみ利用できます。',
    'login.email': 'メールアドレス',
    'login.password': 'パスワード',
    'login.signin': 'ログイン',
    'login.signup': '新規登録',
    'login.have_account': 'すでにアカウントをお持ちですか？ログイン',
    'login.no_account': 'アカウントをお持ちでないですか？新規登録',
    'login.or': 'または',
    'login.policies_prompt': '登録前にコミュニティガイドとポリシーをご確認ください。',
    'login.social.apple': 'Appleで続行',
    'login.social.google': 'Googleで続行',
    'login.social.kakao': 'カカオトークで続行',
    'login.social.naver': 'NAVERで続行',
    'login.email_required': 'メールアドレスを入力してください',
    'login.email_invalid': '正しいメールアドレス形式ではありません',
    'login.password_required': 'パスワードを入力してください',
    'login.password_min': 'パスワードは6文字以上である必要があります',
    'onboarding.skip': 'スキップ',
    'onboarding.next': '次へ',
    'onboarding.start': '始める',
    'policy.community': 'コミュニティガイドライン',
    'policy.terms': '利用規約',
    'policy.privacy': 'プライバシーポリシー',
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

  static I18nProviderState of(BuildContext context) {
    final I18nProviderState? state = context
        .findAncestorStateOfType<I18nProviderState>();
    assert(state != null, 'I18nProvider not found in context');
    return state!;
  }

  @override
  State<I18nProvider> createState() => I18nProviderState();
}

class I18nProviderState extends State<I18nProvider> {
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
