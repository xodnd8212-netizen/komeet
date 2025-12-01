import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../i18n/i18n.dart';

class BottomScaffold extends StatelessWidget {
  final Widget child;
  final int index; // 0=프로필, 1=지금 매칭, 2=채팅, 3=설정
  const BottomScaffold({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.card,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        padding: const EdgeInsets.fromLTRB(8,10,8,12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Item(label: i18n.t('app.profile'),
              icon: index==0?Icons.person:Icons.person_outline,
              onTap: ()=>context.go('/profile')),
            _Item(label: i18n.t('app.match_now'),
              icon: index==1?Icons.favorite:Icons.favorite_border,
              onTap: ()=>context.go('/match')),
            _Item(label: i18n.t('app.chat'),
              icon: index==2?Icons.chat_bubble:Icons.chat_bubble_outline,
              onTap: ()=>context.go('/chat-list')),
            _Item(label: i18n.t('app.settings'),
              icon: index==3?Icons.settings:Icons.settings_outlined,
              onTap: ()=>context.go('/settings')),
          ],
        ),
      ),
      backgroundColor: AppTheme.bg,
    );
  }
}

class _Item extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _Item({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 70,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.text, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.sub)),
      ]),
    ),
  );
}
