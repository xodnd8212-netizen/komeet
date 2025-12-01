import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/match_service.dart';
import '../../services/profile_service.dart';
import '../../models/profile.dart';
import '../../widgets/cached_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../chat/chat_page.dart';

/// 좋아요 알림 페이지 (누가 나를 좋아요 했는지 확인)
class LikesNotificationPage extends StatelessWidget {
  const LikesNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: const Text('나를 좋아요한 사람들', style: TextStyle(color: AppTheme.text)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('type', isEqualTo: 'like')
            .where('read', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: AppTheme.sub),
                  const SizedBox(height: 16),
                  const Text(
                    '아직 좋아요가 없습니다',
                    style: TextStyle(color: AppTheme.sub, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final fromUserId = notification.data()['fromUserId'] as String;
              return FutureBuilder<UserProfile?>(
                future: ProfileService.getProfile(fromUserId),
                builder: (context, profileSnapshot) {
                  if (!profileSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final profile = profileSnapshot.data!;
                  return Card(
                    color: AppTheme.card,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.card,
                        child: profile.photoUrls.isNotEmpty
                            ? ClipOval(
                                child: CachedImage(
                                  imageUrl: profile.photoUrls.first,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person, color: AppTheme.sub),
                      ),
                      title: Text(
                        profile.name,
                        style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${profile.age}세 · ${profile.city}',
                        style: const TextStyle(color: AppTheme.sub),
                      ),
                      trailing: const Icon(Icons.favorite, color: AppTheme.pink),
                      onTap: () async {
                        // 알림 읽음 처리
                        await notification.reference.update({'read': true});
                        
                        // 프로필 상세 보기 또는 매칭 페이지로 이동
                        if (context.mounted) {
                          context.push('/match');
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

