import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../i18n/i18n.dart';

class ChatArgs {
  final String name;
  const ChatArgs({required this.name});
}

class ChatPage extends StatefulWidget {
  final ChatArgs? args;
  const ChatPage({super.key, this.args});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<_Msg> _messages = <_Msg>[
    _Msg(text: '안녕하세요! 初めまして。', isMe: false),
    _Msg(text: '반가워요! お会いできて嬉しいです。', isMe: true, seen: true),
    _Msg(text: '週末は何をしますか？', isMe: false),
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _otherTyping = false;
  bool _canSend = false;

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isMe: true));
    });
    _controller.clear();
    setState(() {
      _canSend = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 64,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    // 데모: 1초 뒤에 읽음 처리
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty) {
          final last = _messages.last;
          if (last.isMe) last.seen = true;
        }
      });
    });
    // 데모: 상대 타이핑 후 자동 응답
    setState(() {
      _otherTyping = true;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _otherTyping = false;
        _messages.add(_Msg(text: '了解です！', isMe: false));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent + 64,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이미지 선택은 추후 연결됩니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final title = widget.args?.name ?? 'Chat';
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: Text(title, style: const TextStyle(color: AppTheme.text)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return _Bubble(
                  text: m.text,
                  isMe: m.isMe,
                  time: m.time,
                  seen: m.seen,
                );
              },
            ),
          ),
          if (_otherTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  i18n.t('chat.typing'),
                  style: const TextStyle(fontSize: 12, color: AppTheme.sub),
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
              if (next != _canSend)
                setState(() {
                  _canSend = next;
                });
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
    if (can != _canSend)
      setState(() {
        _canSend = can;
      });
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool seen;
  const _Bubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.seen,
  });
  @override
  Widget build(BuildContext context) {
    final Color bg = isMe ? const Color(0xFF2A2C45) : AppTheme.card;
    final Alignment align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(color: AppTheme.text)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmt(time),
                  style: const TextStyle(fontSize: 10, color: AppTheme.sub),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(
                    seen ? Icons.done_all : Icons.check,
                    size: 14,
                    color: seen ? AppTheme.pink : AppTheme.sub,
                  ),
                ],
              ],
            ),
          ],
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
      color: AppTheme.card,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onPickImage,
            icon: const Icon(Icons.image_outlined, color: AppTheme.sub),
          ),
          IconButton(
            onPressed: onOpenEmoji,
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              color: AppTheme.sub,
            ),
          ),
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
                border: InputBorder.none,
              ),
              style: const TextStyle(color: AppTheme.text),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: canSend ? onSend : null,
            icon: Icon(
              Icons.send,
              color: canSend ? AppTheme.pink : AppTheme.sub,
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isMe;
  final DateTime time;
  bool seen;
  _Msg({
    required this.text,
    required this.isMe,
    DateTime? time,
    this.seen = false,
  }) : time = time ?? DateTime.now();
}
