import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';
import 'dummy_profiles.dart';
import 'package:go_router/go_router.dart';
import '../chat/chat_page.dart';
import '../../services/prefs.dart';
import '../../services/geo.dart';
import '../../services/location_service.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});
  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  final List<ProfileCardData> _queue = [];

  @override
  void initState() {
    super.initState();
    _reloadQueue();
    _loadLocation();
  }

  Future<void> _reloadQueue() async {
    final tokyoOnly = await PrefsService.getTokyoOnly();
    final maxKm = await PrefsService.getMaxDistanceKm();
    // 데모: 사용자 위치를 도쿄 중심으로 가정
    final user = _userPoint ?? const GeoPoint(35.6762, 139.6503);
    final base = tokyoOnly
        ? demoProfiles.where((p) => p.city.toLowerCase() == 'tokyo').toList()
        : List.of(demoProfiles);
    final list = base.where((p) {
      final d = haversineKm(user, GeoPoint(p.lat, p.lng));
      return d <= maxKm;
    }).toList();
    if (!mounted) return;
    setState(() {
      _queue
        ..clear()
        ..addAll(list);
    });
  }

  GeoPoint? _userPoint;
  Future<void> _loadLocation() async {
    final gp = await LocationService.getCurrentLocation();
    if (gp != null && mounted) {
      setState(() {
        _userPoint = gp;
      });
      await _reloadQueue();
    }
  }

  void _skip() {
    if (_queue.isEmpty) return;
    setState(() {
      _queue.removeAt(0);
    });
  }

  void _like() {
    if (_queue.isEmpty) return;
    final current = _queue.first;
    setState(() {
      _queue.removeAt(0);
    });
    // 매칭 로직/이벤트 훅은 이후 연결
    context.go('/chat', extra: ChatArgs(name: current.name));
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
            i18n.t('match.title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t('match.subtitle'),
            style: const TextStyle(color: AppTheme.sub),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: _queue.isEmpty
                  ? const _Empty()
                  : _CardStack(profiles: _queue, onLike: _like, onSkip: _skip),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                label: i18n.t('match.skip'),
                icon: Icons.close,
                color: Colors.grey,
                onTap: _skip,
              ),
              _ActionButton(
                label: i18n.t('match.like'),
                icon: Icons.favorite,
                color: AppTheme.pink,
                onTap: _like,
              ),
              IconButton(
                onPressed: _reloadQueue,
                icon: const Icon(Icons.refresh, color: AppTheme.sub),
                tooltip: 'Reload',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileCardData data;
  const _ProfileCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420, minHeight: 380),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF22243A),
              alignment: Alignment.center,
              child: const Icon(Icons.person, size: 80, color: Colors.white24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.name}, ${data.age}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(data.city, style: const TextStyle(color: AppTheme.sub)),
                const SizedBox(height: 8),
                Text(data.bio, style: const TextStyle(color: AppTheme.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStack extends StatefulWidget {
  final List<ProfileCardData> profiles;
  final VoidCallback onLike;
  final VoidCallback onSkip;
  const _CardStack({
    required this.profiles,
    required this.onLike,
    required this.onSkip,
  });
  @override
  State<_CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<_CardStack> {
  int _progressDir = 0; // -1, 0, 1
  double _progress = 0; // 0~1 진행도(절댓값)
  @override
  Widget build(BuildContext context) {
    // 상단 2장만 그려 간단한 스택 느낌 제공
    final topTwo = widget.profiles.take(2).toList();
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (topTwo.length == 2)
            Transform.translate(
              offset: const Offset(0, 12),
              child: Opacity(
                opacity: 0.9,
                child: _ProfileCard(data: topTwo[1]),
              ),
            ),
          _buildDismissible(topTwo.first),
          // 진행도 기반 라벨 오버레이
          if (_progress > 0)
            Positioned(
              top: 28,
              left: _progressDir == 1 ? 24 : null,
              right: _progressDir == -1 ? 24 : null,
              child: Opacity(
                opacity: (_progress * 1.2).clamp(0, 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _progressDir == 1 ? AppTheme.pink : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _progressDir == 1
                        ? I18n.of(context).t('match.label.like')
                        : I18n.of(context).t('match.label.skip'),
                    style: TextStyle(
                      color: _progressDir == 1 ? AppTheme.pink : Colors.grey,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDismissible(ProfileCardData data) {
    return Dismissible(
      key: ValueKey('${data.name}-${data.age}-${data.city}'),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 200),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      onUpdate: (details) {
        // 진행도 및 방향(-1: 오른쪽->왼쪽 skip, 1: 왼쪽->오른쪽 like)
        setState(() {
          _progress = details.progress.clamp(0, 1);
          _progressDir = details.direction == DismissDirection.startToEnd
              ? 1
              : -1;
        });
      },
      onDismissed: (dir) {
        setState(() {
          _progress = 0;
        });
        if (dir == DismissDirection.endToStart) {
          widget.onSkip();
        } else {
          widget.onLike();
        }
      },
      background: _SwipeBg(
        icon: Icons.favorite,
        color: AppTheme.pink,
        align: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBg(
        icon: Icons.close,
        color: Colors.grey,
        align: Alignment.centerRight,
      ),
      child: Transform.rotate(
        angle: (_progressDir * _progress) * 0.15, // 최대 ~8.5도 회전
        child: _ProfileCard(data: data),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Alignment align;
  const _SwipeBg({
    required this.icon,
    required this.color,
    required this.align,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkResponse(
          onTap: onTap,
          radius: 36,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.sub)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 420, minHeight: 240),
    alignment: Alignment.center,
    child: Text(
      I18n.of(context).t('match.empty'),
      style: const TextStyle(color: AppTheme.sub),
    ),
  );
}
