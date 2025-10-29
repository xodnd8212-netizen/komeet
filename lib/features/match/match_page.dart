import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class MatchPage extends StatelessWidget {
  const MatchPage({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('지금 매칭', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.text)),
      SizedBox(height: 6),
      Text('위치/취향 기반 추천은 곧 연결합니다.', style: TextStyle(color: AppTheme.sub)),
    ]),
  );
}
