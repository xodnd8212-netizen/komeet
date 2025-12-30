import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';
import '../utils/sanitizer.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'analytics_service.dart';
import 'performance_service.dart';

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

      // 분석 이벤트: 채팅방 열기
      await AnalyticsService.logChatOpened(
        chatId: roomId,
        matchId: roomId, // matchId와 동일하게 사용
      );

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
    final trace = PerformanceService.startTrace('send_message');
    try {
      trace?.start();
      PerformanceService.addAttribute(
        trace,
        'has_image',
        imageUrl != null ? 'true' : 'false',
      );
      PerformanceService.addMetric(trace, 'message_length', text.length);

      final senderId = AuthService.currentUser?.uid;
      if (senderId == null) {
        AppLogger.warning('메시지 전송 실패: 로그인 필요');
        trace?.stop();
        return null;
      }

      // Rate Limiting 확인 (1분에 최대 20개)
      if (!RateLimiter.isAllowed('send_message', 20, 60)) {
        final remaining = RateLimiter.getRemainingSeconds(
          'send_message',
          20,
          60,
        );
        AppLogger.warning('메시지 전송 Rate Limit 초과', {
          'userId': senderId,
          'remainingSeconds': remaining,
        });
        throw Exception(
          '너무 빠르게 메시지를 보내고 있습니다. ${remaining != null ? '$remaining초 후 다시 시도해주세요.' : '잠시 후 다시 시도해주세요.'}',
        );
      }

      // 메시지 Sanitization (XSS 방지, URL/스팸 필터링)
      String sanitizedText;
      try {
        sanitizedText = Sanitizer.sanitizeChatMessage(text, allowUrls: false);
        if (sanitizedText.isEmpty && imageUrl == null) {
          throw Exception('메시지 내용을 입력해주세요.');
        }
      } catch (e) {
        // 필터링 실패 시 사용자에게 에러 표시
        AppLogger.warning('메시지 필터링 실패', {'error': e.toString()});
        rethrow; // UI에서 에러 메시지 표시하도록
      }

      final message = ChatMessage(
        chatId: chatId,
        senderId: senderId,
        text: sanitizedText,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      AppLogger.info('메시지 전송', {
        'chatId': chatId,
        'senderId': senderId,
        'hasImage': imageUrl != null,
      });

      // 첫 메시지인지 확인
      final existingMessages = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isEqualTo: senderId)
          .limit(1)
          .get();

      final isFirstMessage = existingMessages.docs.isEmpty;

      // 채팅방 생성 시간 확인 (첫 메시지 시간 계산용)
      int? timeToFirstMessageMinutes;
      if (isFirstMessage) {
        try {
          final roomDoc = await _firestore
              .collection(_roomsCollection)
              .doc(chatId)
              .get();
          if (roomDoc.exists) {
            final createdAt = roomDoc.data()?['createdAt'];
            if (createdAt != null) {
              final createdAtTime = DateTime.parse(createdAt);
              timeToFirstMessageMinutes = DateTime.now()
                  .difference(createdAtTime)
                  .inMinutes;
            }
          }
        } catch (e) {
          // 무시
        }
      }

      final docRef = await _firestore
          .collection(_messagesCollection)
          .add(message.toMap());

      // 채팅방 마지막 메시지 업데이트
      await _firestore.collection(_roomsCollection).doc(chatId).update({
        'lastMessage': text,
        'lastMessageAt': DateTime.now().toIso8601String(),
      });

      // 분석 이벤트: 메시지 전송
      await AnalyticsService.logMessageSent(
        chatId: chatId,
        hasImage: imageUrl != null,
      );

      // 분석 이벤트: 첫 메시지
      if (isFirstMessage && timeToFirstMessageMinutes != null) {
        await AnalyticsService.logFirstMessageSent(
          chatId: chatId,
          timeToFirstMessageMinutes: timeToFirstMessageMinutes,
        );
      }

      trace?.stop();

      // 상대방에게 채팅 알림 저장 (서버에서 푸시 알림 전송하도록)
      try {
        final roomDoc = await _firestore
            .collection(_roomsCollection)
            .doc(chatId)
            .get();
        if (roomDoc.exists) {
          final participants = List<String>.from(
            roomDoc.data()!['participantIds'] ?? [],
          );
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
      PerformanceService.addAttribute(trace, 'error', e.toString());
      trace?.stop();
      AppLogger.error('메시지 전송 실패', e, stackTrace);
      // 에러 모니터링
      await ErrorService.recordError(
        e,
        stackTrace,
        reason: '메시지 전송 실패',
        fatal: false,
      );
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
      final now = DateTime.now();
      final messages = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('seen', isEqualTo: false)
          .get();

      for (final doc in messages.docs) {
        batch.update(doc.reference, {
          'seen': true,
          'seenAt': now.toIso8601String(),
          'status': MessageStatus.read.name,
        });
      }

      await batch.commit();

      // 채팅방의 읽지 않은 메시지 수 업데이트
      await _firestore.collection(_roomsCollection).doc(chatId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      // 무시
    }
  }

  /// 타이핑 상태 설정
  static Future<void> setTyping(String chatId, bool isTyping) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return;

      final roomRef = _firestore.collection(_roomsCollection).doc(chatId);

      if (isTyping) {
        await roomRef.set({
          'typingUsers.$currentUserId': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } else {
        final roomDoc = await roomRef.get();
        if (roomDoc.exists) {
          final data = roomDoc.data()!;
          final typingUsers = Map<String, dynamic>.from(
            data['typingUsers'] ?? {},
          );
          typingUsers.remove(currentUserId);
          await roomRef.update({'typingUsers': typingUsers});
        }
      }
    } catch (e) {
      // 무시
    }
  }

  /// 타이핑 상태 감시
  static Stream<Map<String, DateTime>> watchTyping(String chatId) {
    final currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value({});
    }

    return _firestore.collection(_roomsCollection).doc(chatId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return {};

      final data = snapshot.data()!;
      final typingUsers = data['typingUsers'] as Map<String, dynamic>?;

      if (typingUsers == null) return {};

      // 5초 이상 지난 타이핑 상태는 제거
      final now = DateTime.now();
      final validTyping = <String, DateTime>{};

      typingUsers.forEach((userId, timestampStr) {
        if (userId != currentUserId) {
          try {
            final timestamp = DateTime.parse(timestampStr);
            if (now.difference(timestamp).inSeconds < 5) {
              validTyping[userId] = timestamp;
            }
          } catch (e) {
            // 무시
          }
        }
      });

      return validTyping;
    });
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
