import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../i18n/i18n.dart';
import '../services/user_safety_service.dart';

/// 사용자 액션 다이얼로그 (차단, 신고, 언매치)
class UserActionDialog extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final bool isMatched;
  final VoidCallback? onActionCompleted;

  const UserActionDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.isMatched = false,
    this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      title: Text(
        targetUserName,
        style: const TextStyle(color: AppTheme.text, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMatched)
            ListTile(
              leading: const Icon(Icons.person_remove, color: AppTheme.pink),
              title: const Text('언매치', style: TextStyle(color: AppTheme.text)),
              onTap: () => _handleUnmatch(context),
            ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('차단하기', style: TextStyle(color: AppTheme.text)),
            onTap: () => _handleBlock(context),
          ),
          ListTile(
            leading: const Icon(Icons.report, color: Colors.orange),
            title: const Text('신고하기', style: TextStyle(color: AppTheme.text)),
            onTap: () => _handleReport(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: AppTheme.sub)),
        ),
      ],
    );
  }

  Future<void> _handleUnmatch(BuildContext context) async {
    Navigator.of(context).pop();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('언매치', style: TextStyle(color: AppTheme.text)),
        content: const Text(
          '이 사용자와의 매칭을 해제하시겠습니까? 채팅 내역은 삭제되지 않지만 더 이상 대화할 수 없습니다.',
          style: TextStyle(color: AppTheme.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: AppTheme.sub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('언매치', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await UserSafetyService.unmatchUser(targetUserId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '언매치되었습니다.' : '언매치에 실패했습니다.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        onActionCompleted?.call();
      }
    }
  }

  Future<void> _handleBlock(BuildContext context) async {
    Navigator.of(context).pop();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('차단하기', style: TextStyle(color: AppTheme.text)),
        content: const Text(
          '이 사용자를 차단하시겠습니까? 차단된 사용자는 더 이상 프로필을 볼 수 없고 메시지를 보낼 수 없습니다.',
          style: TextStyle(color: AppTheme.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: AppTheme.sub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('차단', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await UserSafetyService.blockUser(targetUserId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '차단되었습니다.' : '차단에 실패했습니다.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        onActionCompleted?.call();
      }
    }
  }

  Future<void> _handleReport(BuildContext context) async {
    Navigator.of(context).pop();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReportReasonDialog(),
    );

    if (reason != null && context.mounted) {
      final description = await showDialog<String>(
        context: context,
        builder: (ctx) => _ReportDescriptionDialog(),
      );

      if (description != null) {
        final success = await UserSafetyService.reportUser(
          targetUserId: targetUserId,
          reason: reason,
          description: description,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success 
                  ? '신고가 접수되었습니다. 검토 후 조치하겠습니다.' 
                  : '신고 접수에 실패했습니다.',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ReportReasonDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reasons = [
      '부적절한 사진',
      '스팸 또는 사기',
      '괴롭힘 또는 혐오 발언',
      '가짜 프로필',
      '기타',
    ];

    return AlertDialog(
      backgroundColor: AppTheme.card,
      title: const Text('신고 사유', style: TextStyle(color: AppTheme.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: reasons.map((reason) {
          return ListTile(
            title: Text(reason, style: const TextStyle(color: AppTheme.text)),
            onTap: () => Navigator.of(context).pop(reason),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: AppTheme.sub)),
        ),
      ],
    );
  }
}

class _ReportDescriptionDialog extends StatefulWidget {
  @override
  State<_ReportDescriptionDialog> createState() => _ReportDescriptionDialogState();
}

class _ReportDescriptionDialogState extends State<_ReportDescriptionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      title: const Text('상세 설명', style: TextStyle(color: AppTheme.text)),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: '신고 사유를 자세히 설명해주세요 (선택사항)',
          hintStyle: TextStyle(color: AppTheme.sub),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(color: AppTheme.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: AppTheme.sub)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('제출', style: TextStyle(color: AppTheme.pink)),
        ),
      ],
    );
  }
}

