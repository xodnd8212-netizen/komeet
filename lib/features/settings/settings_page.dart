import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.text)),
      SizedBox(height: 6),
      Text('알림/언어(ko/ja)/최대 거리/필터를 조정하세요.', style: TextStyle(color: AppTheme.sub)),
    ]),
  );
}
