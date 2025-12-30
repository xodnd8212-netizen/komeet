import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/verification_service.dart';
import '../../widgets/cached_image.dart';
import 'profile_edit_dialog.dart';
import 'verification_request_page.dart';
import '../store/coin_store_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool? _isVerified;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final verified = await VerificationService.isVerified();
    if (mounted) {
      setState(() {
        _isVerified = verified;
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? _buildEmptyProfile(i18n)
          : _buildProfileDisplay(i18n),
    );
  }

  Widget _buildEmptyProfile(I18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.t('home.title'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          i18n.t('home.subtitle'),
          style: const TextStyle(color: AppTheme.sub),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await showDialog<UserProfile?>(
              context: context,
              builder: (_) => const ProfileEditDialog(),
            );
            if (result != null && mounted) {
              await _loadProfile();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('프로필이 저장되었습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.person_add),
          label: const Text('프로필 작성하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.pink,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDisplay(I18n i18n) {
    final p = _profile!;
    final flagEmoji =
        p.city.contains('서울') == true || p.city.contains('Seoul') == true
        ? '🇰🇷'
        : '🇯🇵';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream(),
      builder: (context, snapshot) {
        final coinBalance = snapshot.data?.data()?['coinBalance'] ?? 0;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Card
                Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        height: 96,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF5C8A),
                              Color(0xFF9C27B0),
                              Color(0xFF2196F3),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -48),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: p.photoUrls.isNotEmpty
                                          ? CachedImage(
                                              imageUrl: p.photoUrls.first,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: AppTheme.card,
                                              child: const Icon(
                                                Icons.person,
                                                size: 40,
                                                color: AppTheme.sub,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.text,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  flagEmoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${p.age}세 · ${p.city}',
                                  style: const TextStyle(color: AppTheme.sub),
                                ),
                                if (_isVerified == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          '인증됨',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_isVerified != true)
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const VerificationRequestPage(),
                                        ),
                                      );
                                      await _loadVerificationStatus();
                                    },
                                    icon: const Icon(
                                      Icons.verified_user,
                                      size: 16,
                                    ),
                                    label: const Text('인증하기'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      side: const BorderSide(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final result =
                                        await showDialog<UserProfile?>(
                                          context: context,
                                          builder: (_) => ProfileEditDialog(
                                            initialProfile: p,
                                          ),
                                        );
                                    if (result != null && mounted) {
                                      await _loadProfile();
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('프로필이 업데이트되었습니다.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppTheme.pink,
                                  ),
                                  label: const Text(
                                    '수정',
                                    style: TextStyle(color: AppTheme.pink),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Coins Card
                Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFF9E6),
                          const Color(0xFFFFF3E0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '보유 코인',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$coinBalance 코인',
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => CoinStoreDialog(),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag, size: 16),
                          label: const Text('충전'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bio & Details Card
                Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 16,
                              color: Color(0xFFFF5C8A),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '소개',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.bio,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (p.interests.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: p.interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.pink.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.pink.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: AppTheme.pink,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Settings Card
                Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.settings,
                              size: 16,
                              color: AppTheme.text,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '설정',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.shopping_bag,
                          color: AppTheme.text,
                        ),
                        title: const Text(
                          '코인 스토어',
                          style: TextStyle(color: AppTheme.text),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => CoinStoreDialog(),
                          );
                        },
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('type', isEqualTo: 'like')
                            .where('read', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.hasData
                              ? snapshot.data!.docs.length
                              : 0;
                          return ListTile(
                            leading: Stack(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: AppTheme.text,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.pink,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: const Text(
                              '나를 좋아요한 사람들',
                              style: TextStyle(color: AppTheme.text),
                            ),
                            trailing: unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pink,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              context.push('/likes');
                            },
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.security,
                          color: AppTheme.text,
                        ),
                        title: const Text(
                          '개인정보 및 보안',
                          style: TextStyle(color: AppTheme.text),
                        ),
                        onTap: () {
                          // TODO: 개인정보 및 보안 페이지
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          '로그아웃',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          await AuthService.signOut();
                          if (mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
