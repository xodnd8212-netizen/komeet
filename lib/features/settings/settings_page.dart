import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';
import '../../services/prefs.dart';
import '../../services/notifications.dart';
import '../../services/auth_service.dart';
import '../../services/prefs.dart' as prefs_ext; // for onboarding reset
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _maxDistance = 30;
  bool _notify = true;
  bool _tokyoOnly = false;
  int _minAge = 18;
  int _maxAge = 99;
  String _genderPreference = 'any';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await PrefsService.getMaxDistanceKm();
    final n = await PrefsService.getNotificationsEnabled();
    final t = await PrefsService.getTokyoOnly();
    final minAge = await PrefsService.getMinAge();
    final maxAge = await PrefsService.getMaxAge();
    final genderPref = await PrefsService.getGenderPreference();
    if (!mounted) return;
    setState(() {
      _maxDistance = d;
      _notify = n;
      _tokyoOnly = t;
      _minAge = minAge;
      _maxAge = maxAge;
      _genderPreference = genderPref;
    });
    await NotificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.t('settings.title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t('settings.subtitle'),
            style: const TextStyle(color: AppTheme.sub),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.pink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              i18n.t('settings.age_badge'),
              style: const TextStyle(
                color: AppTheme.pink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            i18n.t('settings.language'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          const _LanguageSelector(),
          const SizedBox(height: 24),
          Text(
            i18n.t('settings.max_distance'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  min: 0.1,
                  max: 200,
                  divisions: 1999,
                  value: _maxDistance,
                  label: _maxDistance.toStringAsFixed(1),
                  onChanged: (v) {
                    setState(() => _maxDistance = v);
                  },
                  onChangeEnd: (v) {
                    PrefsService.setMaxDistanceKm(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_maxDistance.toStringAsFixed(1)} km',
                style: const TextStyle(color: AppTheme.sub),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(
              i18n.t('settings.notifications'),
              style: const TextStyle(color: AppTheme.text),
            ),
            value: _notify,
            onChanged: (v) {
              setState(() => _notify = v);
              PrefsService.setNotificationsEnabled(v);
              NotificationService.setEnabled(v);
            },
          ),
          if (_notify)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => NotificationService.showDemo(
                  context,
                  body: '푸시 알림 테스트(데모)',
                ),
                icon: const Icon(
                  Icons.notifications_active,
                  color: AppTheme.sub,
                ),
                label: const Text(
                  '알림 테스트',
                  style: TextStyle(color: AppTheme.sub),
                ),
              ),
            ),
          SwitchListTile(
            title: Text(
              i18n.t('settings.filter.tokyo_only'),
              style: const TextStyle(color: AppTheme.text),
            ),
            value: _tokyoOnly,
            onChanged: (v) {
              setState(() => _tokyoOnly = v);
              PrefsService.setTokyoOnly(v);
            },
          ),
          const SizedBox(height: 24),
          Text(
            '나이 범위',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('최소 나이: $_minAge세', style: const TextStyle(color: AppTheme.text)),
                    Slider(
                      min: 18,
                      max: 99,
                      divisions: 81,
                      value: _minAge.toDouble(),
                      label: '$_minAge세',
                      onChanged: (v) {
                        setState(() {
                          _minAge = v.toInt();
                          if (_minAge > _maxAge) _maxAge = _minAge;
                        });
                      },
                      onChangeEnd: (v) {
                        PrefsService.setMinAge(v.toInt());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('최대 나이: $_maxAge세', style: const TextStyle(color: AppTheme.text)),
                    Slider(
                      min: 18,
                      max: 99,
                      divisions: 81,
                      value: _maxAge.toDouble(),
                      label: '$_maxAge세',
                      onChanged: (v) {
                        setState(() {
                          _maxAge = v.toInt();
                          if (_maxAge < _minAge) _minAge = _maxAge;
                        });
                      },
                      onChangeEnd: (v) {
                        PrefsService.setMaxAge(v.toInt());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '성별 선호도',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _GenderOption(
                label: '전체',
                value: 'any',
                selected: _genderPreference,
                onChanged: (v) {
                  setState(() => _genderPreference = v);
                  PrefsService.setGenderPreference(v);
                },
              ),
              _GenderOption(
                label: '남성',
                value: 'male',
                selected: _genderPreference,
                onChanged: (v) {
                  setState(() => _genderPreference = v);
                  PrefsService.setGenderPreference(v);
                },
              ),
              _GenderOption(
                label: '여성',
                value: 'female',
                selected: _genderPreference,
                onChanged: (v) {
                  setState(() => _genderPreference = v);
                  PrefsService.setGenderPreference(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const _ChatDemoEntry())),
            child: Text(i18n.t('settings.open_chat_demo')),
          ),
          const SizedBox(height: 24),
          Text(
            i18n.t('settings.policy_title'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              i18n.t('coin.store_title'),
              style: const TextStyle(color: AppTheme.text),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.sub),
            onTap: () => context.push('/coin-store'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              i18n.t('policy.community'),
              style: const TextStyle(color: AppTheme.text),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.sub),
            onTap: () => context.push('/policy/community'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              i18n.t('policy.terms'),
              style: const TextStyle(color: AppTheme.text),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.sub),
            onTap: () => context.push('/policy/terms'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              i18n.t('policy.privacy'),
              style: const TextStyle(color: AppTheme.text),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.sub),
            onTap: () => context.push('/policy/privacy'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout, color: AppTheme.pink),
            label: const Text('로그아웃', style: TextStyle(color: AppTheme.pink)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.pink),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await prefs_ext.PrefsService.setOnboardingCompleted(false);
              if (!context.mounted) return;
              context.go('/onboarding');
            },
            icon: const Icon(Icons.refresh, color: AppTheme.sub),
            label: Text(
              i18n.t('settings.reset_onboarding'),
              style: const TextStyle(color: AppTheme.sub),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                // 메모리 캐시 비우기
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                // 디스크 캐시 비우기 (cached_network_image 기반)
                await DefaultCacheManager().emptyCache();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(i18n.t('settings.cache_cleared'))),
                );
              } catch (_) {}
            },
            icon: const Icon(Icons.cleaning_services, color: AppTheme.sub),
            label: Text(
              i18n.t('settings.clear_cache'),
              style: const TextStyle(color: AppTheme.sub),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final state = I18nProvider.of(context);
    final AppLocale current = i18n.locale;

    RadioMenuButton<AppLocale> buildOption(AppLocale value, String label) {
      return RadioMenuButton<AppLocale>(
        value: value,
        groupValue: current,
        onChanged: (selected) {
          if (selected != null) {
            state.setLocale(selected);
          }
        },
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(AppTheme.text),
        ),
        child: Text(label),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        buildOption(AppLocale.ko, i18n.t('settings.lang.ko')),
        buildOption(AppLocale.ja, i18n.t('settings.lang.ja')),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _GenderOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(value),
      selectedColor: AppTheme.pink.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.pink : AppTheme.text,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

class _ChatDemoEntry extends StatelessWidget {
  const _ChatDemoEntry();
  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(child: Text(i18n.t('settings.chat_route_hint'))),
      ),
    );
  }
}
