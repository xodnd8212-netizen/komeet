enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String? id;
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool seen;
  final DateTime? seenAt;
  final MessageStatus status;

  ChatMessage({
    this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.seen = false,
    this.seenAt,
    this.status = MessageStatus.sent,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'seen': seen,
      'seenAt': seenAt?.toIso8601String(),
      'status': status.name,
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      seen: map['seen'] ?? false,
      seenAt: map['seenAt'] != null ? DateTime.parse(map['seenAt']) : null,
      status: map['status'] != null 
          ? MessageStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => MessageStatus.sent,
            )
          : MessageStatus.sent,
    );
  }
  
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? seen,
    DateTime? seenAt,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      seen: seen ?? this.seen,
      seenAt: seenAt ?? this.seenAt,
      status: status ?? this.status,
    );
  }
}

class ChatRoom {
  final String? id;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final int unreadCount;
  final Map<String, DateTime>? typingUsers; // 타이핑 중인 사용자들

  ChatRoom({
    this.id,
    required this.participantIds,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.typingUsers,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'typingUsers': typingUsers?.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  factory ChatRoom.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoom(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.parse(map['lastMessageAt'])
          : null,
      lastMessage: map['lastMessage'],
      unreadCount: map['unreadCount'] ?? 0,
      typingUsers: map['typingUsers'] != null
          ? Map<String, DateTime>.from(
              (map['typingUsers'] as Map).map(
                (k, v) => MapEntry(k, DateTime.parse(v)),
              ),
            )
          : null,
    );
  }
}

