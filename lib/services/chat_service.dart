import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';
import '../utils/sanitizer.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _messagesCollection = 'messages';
  static const String _roomsCollection = 'chatRooms';

  static Future<String?> createChatRoom(String otherUserId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return null;

      final participants = [currentUserId, otherUserId]..sort();
      final roomId = participants.join('_');

      // 기존 채팅방 확인
      final existingRoom = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .get();

      if (existingRoom.exists) {
        return roomId;
      }

      // 새 채팅방 생성
      final room = ChatRoom(
        id: roomId,
        participantIds: participants,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .set(room.toMap());

      AppLogger.info('채팅방 생성/조회', {
        'roomId': roomId,
        'userId': currentUserId,
        'otherUserId': otherUserId,
      });
      return roomId;
    } catch (e, stackTrace) {
      AppLogger.error('채팅방 생성 실패', e, stackTrace);
      return null;
    }
  }

  static Future<String?> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final senderId = AuthService.currentUser?.uid;
      if (senderId == null) {
        AppLogger.warning('메시지 전송 실패: 로그인 필요');
        return null;
      }

      // Rate Limiting 확인 (1분에 최대 20개)
      if (!RateLimiter.isAllowed('send_message', 20, 60)) {
        final remaining = RateLimiter.getRemainingSeconds('send_message', 20, 60);
        AppLogger.warning('메시지 전송 Rate Limit 초과', {
          'userId': senderId,
          'remainingSeconds': remaining,
        });
        throw Exception('너무 빠르게 메시지를 보내고 있습니다. ${remaining != null ? '${remaining}초 후 다시 시도해주세요.' : '잠시 후 다시 시도해주세요.'}');
      }

      // 메시지 Sanitization (XSS 방지)
      final sanitizedText = Sanitizer.sanitizeChatMessage(text);
      if (sanitizedText.isEmpty && imageUrl == null) {
        throw Exception('메시지 내용을 입력해주세요.');
      }

      final message = ChatMessage(
        chatId: chatId,
        senderId: senderId,
        text: sanitizedText,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      AppLogger.info('메시지 전송', {
        'chatId': chatId,
        'senderId': senderId,
        'hasImage': imageUrl != null,
      });

      final docRef = await _firestore
          .collection(_messagesCollection)
          .add(message.toMap());

      // 채팅방 마지막 메시지 업데이트
      await _firestore.collection(_roomsCollection).doc(chatId).update({
        'lastMessage': text,
        'lastMessageAt': DateTime.now().toIso8601String(),
      });

      // 상대방에게 채팅 알림 저장 (서버에서 푸시 알림 전송하도록)
      try {
        final roomDoc = await _firestore.collection(_roomsCollection).doc(chatId).get();
        if (roomDoc.exists) {
          final participants = List<String>.from(roomDoc.data()!['participantIds'] ?? []);
          final receiverId = participants.firstWhere(
            (id) => id != senderId,
            orElse: () => '',
          );

          if (receiverId.isNotEmpty) {
            // Firestore에 알림 데이터 저장
            await _firestore.collection('notifications').add({
              'type': 'chat',
              'userId': receiverId,
              'fromUserId': senderId,
              'chatId': chatId,
              'message': text,
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            });

            // 상대방 프로필 가져오기 (알림에 이름 표시용)
            final senderProfile = await ProfileService.getProfile(senderId);
            if (senderProfile != null) {
              // 로컬 알림도 표시 (앱이 포그라운드에 있을 때)
              // 실제 푸시 알림은 서버에서 처리
            }
          }
        }
      } catch (e) {
        // 알림 저장 실패는 무시
      }

      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('메시지 전송 실패', e, stackTrace);
      rethrow;
    }
  }

  static Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  static Future<void> markAsSeen(String chatId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return;

      final batch = _firestore.batch();
      final messages = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('seen', isEqualTo: false)
          .get();

      for (final doc in messages.docs) {
        batch.update(doc.reference, {'seen': true});
      }

      await batch.commit();
    } catch (e) {
      // 무시
    }
  }

  static Stream<List<ChatRoom>> watchChatRooms() {
    final currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_roomsCollection)
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            // 비활성화된 채팅방 제외
            return data['isActive'] != false;
          })
          .map((doc) => ChatRoom.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}

