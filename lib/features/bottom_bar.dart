import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';

class BottomScaffold extends StatelessWidget {
  final Widget child;
  final int index; // 0=프로필, 1=지금 매칭, 2=설정
  const BottomScaffold({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.card,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        padding: const EdgeInsets.fromLTRB(16,10,16,12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Item(label: '내 프로필',
              icon: index==0?Icons.person:Icons.person_outline,
              onTap: ()=>context.go('/profile')),
            _CenterMatch(onTap: ()=>context.go('/match')),
            _Item(label: '설정',
              icon: index==2?Icons.settings:Icons.settings_outlined,
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
      width: 90,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.text),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.sub)),
      ]),
    ),
  );
}

class _CenterMatch extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterMatch({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 64, height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFFF6EA9), Color(0xFFFF4F7D)]),
      ),
      child: const Icon(Icons.favorite, color: Colors.white),
    ),
  );
}
