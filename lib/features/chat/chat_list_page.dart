import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';
import '../../services/chat_service.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../models/profile.dart';
import '../../models/chat_message.dart';
import '../../widgets/cached_image.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: Text(i18n.t('chat.title'), style: const TextStyle(color: AppTheme.text)),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: ChatService.watchChatRooms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE3F2FD), Color(0xFFE1BEE7)],
                      ),
                      borderRadius: BorderRadius.circular(48),
                    ),
                    child: const Icon(
                      Icons.message_outlined,
                      size: 48,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '대화를 시작해보세요',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '매칭된 사람과 메시지를 주고받아보세요!',
                    style: const TextStyle(color: AppTheme.sub),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _ChatRoomTile(room: room);
            },
          );
        },
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  const _ChatRoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUser?.uid ?? '';
    final otherUserId = room.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => room.participantIds.isNotEmpty ? room.participantIds.first : '',
    );

    return FutureBuilder<UserProfile?>(
      future: ProfileService.getProfile(otherUserId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.name ?? 'Unknown';
        final photoUrl = profile?.photoUrls.isNotEmpty == true ? profile!.photoUrls.first : null;
        final nationality = profile?.city.contains('서울') == true || profile?.city.contains('Seoul') == true
            ? 'KR'
            : 'JP';
        final flagEmoji = nationality == 'KR' ? '🇰🇷' : '🇯🇵';

        return Card(
          color: AppTheme.card,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              context.go(
                '/chat',
                extra: ChatArgs(
                  name: name,
                  chatId: room.id,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipOval(
                    child: photoUrl != null
                        ? CachedImage(
                            imageUrl: photoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: AppTheme.card,
                            child: const Icon(Icons.person, color: AppTheme.sub),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppTheme.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              flagEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.lastMessage ?? '메시지를 보내보세요',
                          style: TextStyle(
                            color: AppTheme.sub,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (room.lastMessageAt != null)
                    Text(
                      _formatTime(room.lastMessageAt!),
                      style: const TextStyle(
                        color: AppTheme.sub,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.month}/${time.day}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

