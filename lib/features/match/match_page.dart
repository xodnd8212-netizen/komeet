import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';
import 'package:go_router/go_router.dart';
import '../chat/chat_page.dart';
import '../../services/prefs.dart';
import '../../services/geo.dart' as mygeo;
import '../../services/location_service.dart';
import '../../services/match_service.dart';
import '../../models/profile.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/user_action_dialog.dart';
import '../../services/premium_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});
  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  final List<UserProfile> _queue = [];
  bool _isLoading = true;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _reloadQueue() async {
    setState(() => _isLoading = true);
    final tokyoOnly = await PrefsService.getTokyoOnly();
    final maxKm = await PrefsService.getMaxDistanceKm();
    final user = _userPoint ?? const mygeo.GeoPoint(35.6762, 139.6503);
    final result = await MatchService.getRecommendationsWithPagination(
      lat: user.lat,
      lng: user.lng,
      maxDistanceKm: maxKm,
      tokyoOnly: tokyoOnly,
      limit: 20,
      lastDocument: null,
    );

    if (!mounted) return;
    setState(() {
      _queue
        ..clear()
        ..addAll(result.profiles);
      _isLoading = false;
      _lastDoc = result.lastDocument;
      _hasMore = result.hasMore;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);
    final tokyoOnly = await PrefsService.getTokyoOnly();
    final maxKm = await PrefsService.getMaxDistanceKm();
    final user = _userPoint ?? const mygeo.GeoPoint(35.6762, 139.6503);
    final result = await MatchService.getRecommendationsWithPagination(
      lat: user.lat,
      lng: user.lng,
      maxDistanceKm: maxKm,
      tokyoOnly: tokyoOnly,
      limit: 20,
      lastDocument: _lastDoc,
    );
    if (!mounted) return;
    setState(() {
      _queue.addAll(result.profiles);
      _isLoading = false;
      _lastDoc = result.lastDocument;
      _hasMore = result.hasMore;
    });
  }

  mygeo.GeoPoint? _userPoint;
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

  Future<void> _like() async {
    if (_queue.isEmpty) return;
    final current = _queue.first;
    if (current.id == null) {
      setState(() => _queue.removeAt(0));
      return;
    }

    setState(() => _queue.removeAt(0));

    final isMatch = await MatchService.likeUser(current.id!);
    if (!mounted) return;

    if (isMatch) {
      // 매칭 성공!
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text('매칭 성공!', style: TextStyle(color: AppTheme.text)),
          content: Text('${current.name}님과 매칭되었습니다!', style: const TextStyle(color: AppTheme.text)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(
                  '/chat',
                  extra: ChatArgs(
                    name: current.name,
                    otherUserId: current.id,
                  ),
                );
              },
              child: const Text('채팅하기', style: TextStyle(color: AppTheme.pink)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _superLike() async {
    if (_queue.isEmpty) return;
    final current = _queue.first;
    if (current.id == null) {
      setState(() => _queue.removeAt(0));
      return;
    }

    final success = await PremiumService.sendSuperLike(current.id!);
    if (!mounted) return;

    if (success) {
      setState(() => _queue.removeAt(0));
      final isMatch = await MatchService.likeUser(current.id!);
      if (!mounted) return;

      if (isMatch) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.card,
            title: const Text('슈퍼라이크 매칭!', style: TextStyle(color: AppTheme.text)),
            content: Text('${current.name}님과 슈퍼라이크로 매칭되었습니다!', style: const TextStyle(color: AppTheme.text)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(
                    '/chat',
                    extra: ChatArgs(
                      name: current.name,
                      otherUserId: current.id,
                    ),
                  );
                },
                child: const Text('채팅하기', style: TextStyle(color: AppTheme.pink)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('슈퍼라이크를 보냈습니다!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('슈퍼라이크 전송에 실패했습니다.')),
      );
    }
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
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _queue.isEmpty
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
              FutureBuilder<bool>(
                future: PremiumService.canUseSuperLike(),
                builder: (context, snapshot) {
                  final canSuperLike = snapshot.data ?? false;
                  return _ActionButton(
                    label: canSuperLike ? '슈퍼라이크' : i18n.t('match.like'),
                    icon: canSuperLike ? Icons.star : Icons.favorite,
                    color: canSuperLike ? Colors.blue : AppTheme.pink,
                    onTap: canSuperLike ? () => _superLike() : _like,
                  );
                },
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
              if (_hasMore)
                OutlinedButton(
                  onPressed: _loadMore,
                  child: const Text('더 보기', style: TextStyle(color: AppTheme.text)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  const _ProfileCard({required this.profile});
  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;
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
          Stack(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF22243A),
                  child: photoUrl != null
                      ? CachedImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 80, color: Colors.white24),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    if (profile.id != null) {
                      showDialog(
                        context: context,
                        builder: (ctx) => UserActionDialog(
                          targetUserId: profile.id!,
                          targetUserName: profile.name,
                          isMatched: false,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${profile.name}, ${profile.age}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(profile.city, style: const TextStyle(color: AppTheme.sub)),
                const SizedBox(height: 8),
                Text(profile.bio, style: const TextStyle(color: AppTheme.text)),
                if (profile.interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: profile.interests.take(3).map((interest) => Chip(
                      label: Text(interest, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStack extends StatefulWidget {
  final List<UserProfile> profiles;
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
                child: _ProfileCard(profile: topTwo[1]),
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
          // 하트/엑스 아이콘 오버레이 애니메이션
          if (_progress > 0.7)
            Center(
              child: AnimatedScale(
                scale: (_progress - 0.7) * 3.33,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  _progressDir == 1 ? Icons.favorite : Icons.close,
                  size: 80,
                  color: _progressDir == 1
                      ? AppTheme.pink.withValues(alpha: 0.8)
                      : Colors.grey.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDismissible(UserProfile profile) {
    return Dismissible(
      key: ValueKey('${profile.id ?? profile.name}-${profile.age}-${profile.city}'),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 250),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      resizeDuration: const Duration(milliseconds: 200),
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
        angle: (_progressDir * _progress) * 0.15,
        child: AnimatedScale(
          scale: _progress > 0 ? (1.0 - _progress * 0.05) : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: _ProfileCard(profile: profile),
        ),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
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
