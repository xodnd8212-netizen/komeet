import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/user_action_dialog.dart';

class ChatArgs {
  final String name;
  final String? chatId;
  final String? otherUserId;
  const ChatArgs({required this.name, this.chatId, this.otherUserId});
}

class ChatPage extends StatefulWidget {
  final ChatArgs? args;
  const ChatPage({super.key, this.args});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _chatId;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final bool _otherTyping = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (widget.args?.chatId != null) {
      setState(() => _chatId = widget.args!.chatId);
      ChatService.markAsSeen(_chatId!);
    } else if (widget.args?.otherUserId != null) {
      final roomId = await ChatService.createChatRoom(
        widget.args!.otherUserId!,
      );
      if (mounted && roomId != null) {
        setState(() => _chatId = roomId);
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatId == null) return;

    _controller.clear();
    setState(() => _canSend = false);

    await ChatService.sendMessage(chatId: _chatId!, text: text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 64,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    if (_chatId == null) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) return;

      // 이미지 업로드
      final imageUrl = await StorageService.uploadProfileImage(
        bytes,
        'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (imageUrl != null && mounted) {
        await ChatService.sendMessage(
          chatId: _chatId!,
          text: '',
          imageUrl: imageUrl,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 업로드에 실패했습니다.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final title = widget.args?.name ?? 'Chat';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.card,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: AppTheme.text, fontSize: 16),
            ),
            const SizedBox(width: 4),
            const Text('🇰🇷', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.text),
            onSelected: (value) {
              if (value == 'actions' && widget.args?.otherUserId != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => UserActionDialog(
                    targetUserId: widget.args!.otherUserId!,
                    targetUserName: title,
                    isMatched: true,
                    onActionCompleted: () {
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'actions',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: AppTheme.text),
                    SizedBox(width: 8),
                    Text('사용자 설정', style: TextStyle(color: AppTheme.text)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _chatId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.watchMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data!;
                      final currentUserId = AuthService.currentUser?.uid ?? '';
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scroll.hasClients && messages.isNotEmpty) {
                          _scroll.animateTo(
                            _scroll.position.maxScrollExtent + 100,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            '대화를 시작해보세요! 👋',
                            style: const TextStyle(color: AppTheme.sub),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final m = messages[i];
                          final isMe = m.senderId == currentUserId;
                          return _Bubble(
                            text: m.text,
                            isMe: isMe,
                            time: m.timestamp,
                            seen: m.seen,
                            imageUrl: m.imageUrl,
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_otherTyping)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 6,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        i18n.t('chat.typing'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.sub,
                        ),
                      ),
                    ),
                  ),
                _InputBar(
                  controller: _controller,
                  onSend: _send,
                  hintText: i18n.t('chat.placeholder'),
                  canSend: _canSend,
                  onChanged: (v) {
                    final next = v.trim().isNotEmpty;
                    if (next != _canSend) {
                      setState(() {
                        _canSend = next;
                      });
                    }
                  },
                  onPickImage: _pickImage,
                  onOpenEmoji: _openEmojiPicker,
                ),
              ],
            ),
    );
  }

  Future<void> _openEmojiPicker() async {
    final sel = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.card,
      builder: (ctx) {
        const emojis = [
          '😀',
          '😍',
          '🥰',
          '😘',
          '😂',
          '😎',
          '👍',
          '👏',
          '🙏',
          '🔥',
          '💖',
          '🇯🇵',
          '🇰🇷',
        ];
        return SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: emojis.length,
            itemBuilder: (cellCtx, i) => InkWell(
              onTap: () => Navigator.of(cellCtx).pop(emojis[i]),
              child: Center(
                child: Text(emojis[i], style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
        );
      },
    );
    if (sel == null) return;
    final text = _controller.text;
    final selStart = _controller.selection.start;
    final selEnd = _controller.selection.end;
    final start = selStart >= 0 ? selStart : text.length;
    final end = selEnd >= 0 ? selEnd : text.length;
    final next = text.replaceRange(start, end, sel);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + sel.length),
    );
    final can = next.trim().isNotEmpty;
    if (can != _canSend) {
      setState(() {
        _canSend = can;
      });
    }
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool seen;
  final String? imageUrl;
  const _Bubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.seen,
    this.imageUrl,
  });
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [Color(0xFFFF5C8A), Color(0xFF9C27B0)],
                  )
                : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                CachedImage(
                  imageUrl: imageUrl!,
                  width: 220,
                  borderRadius: BorderRadius.circular(8),
                  fit: BoxFit.cover,
                )
              else if (text.isNotEmpty)
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 15,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                _fmt(time),
                style: TextStyle(
                  fontSize: 11,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final bool canSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickImage;
  final VoidCallback onOpenEmoji;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.hintText,
    required this.canSend,
    required this.onChanged,
    required this.onPickImage,
    required this.onOpenEmoji,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: (_) {
                    if (canSend) onSend();
                  },
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppTheme.sub),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Color(0xFF9C27B0),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.text),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: canSend
                      ? const LinearGradient(
                          colors: [Color(0xFFFF5C8A), Color(0xFF9C27B0)],
                        )
                      : null,
                  color: canSend ? null : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF5C8A).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  onPressed: canSend ? onSend : null,
                  icon: Icon(
                    Icons.send,
                    color: canSend ? Colors.white : AppTheme.sub,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⌨️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '키보드를 사용하여 입력하세요',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.sub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
