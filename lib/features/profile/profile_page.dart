import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(i18n.t('home.title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.text)),
        const SizedBox(height: 8),
        Text(i18n.t('home.subtitle'), style: const TextStyle(color: AppTheme.sub)),
      ]),
    );
  }
}
