import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('코밋 Komeet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.text)),
      SizedBox(height: 8),
      Text('내 프로필을 설정하세요. (사진/소개/관심사/선호 거리)', style: TextStyle(color: AppTheme.sub)),
    ]),
  );
}
