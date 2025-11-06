import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';
import '../../services/prefs.dart';
import '../../services/notifications.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _maxDistance = 30;
  bool _notify = true;
  bool _tokyoOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await PrefsService.getMaxDistanceKm();
    final n = await PrefsService.getNotificationsEnabled();
    final t = await PrefsService.getTokyoOnly();
    if (!mounted) return;
    setState(() {
      _maxDistance = d;
      _notify = n;
      _tokyoOnly = t;
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
          const SizedBox(height: 16),
          Text(
            i18n.t('settings.language'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          _LanguageSelector(),
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
                  min: 1,
                  max: 100,
                  divisions: 99,
                  value: _maxDistance,
                  label: _maxDistance.toStringAsFixed(0),
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
                '${_maxDistance.toStringAsFixed(0)} km',
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const _ChatDemoEntry())),
            child: Text(i18n.t('settings.open_chat_demo')),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final state = I18nProvider.of(context);
    final AppLocale current = i18n.locale;
    return Column(
      children: [
        RadioListTile<AppLocale>(
          value: AppLocale.ko,
          groupValue: current,
          onChanged: (v) {
            if (v != null) state.setLocale(v);
          },
          title: Text(
            i18n.t('settings.lang.ko'),
            style: const TextStyle(color: AppTheme.text),
          ),
        ),
        RadioListTile<AppLocale>(
          value: AppLocale.ja,
          groupValue: current,
          onChanged: (v) {
            if (v != null) state.setLocale(v);
          },
          title: Text(
            i18n.t('settings.lang.ja'),
            style: const TextStyle(color: AppTheme.text),
          ),
        ),
      ],
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
