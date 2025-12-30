import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme.dart';
import '../../services/verification_service.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/cached_image.dart';

/// 인증 요청 검토 페이지 (관리자 전용)
class VerificationReviewPage extends StatefulWidget {
  const VerificationReviewPage({super.key});

  @override
  State<VerificationReviewPage> createState() => _VerificationReviewPageState();
}

class _VerificationReviewPageState extends State<VerificationReviewPage> {
  List<Map<String, dynamic>> _verifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    setState(() => _isLoading = true);
    try {
      final verifications = await VerificationService.getPendingVerifications();
      setState(() {
        _verifications = verifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로드 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approveVerification(Map<String, dynamic> verification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인증 승인'),
        content: const Text('이 인증 요청을 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final adminId = AuthService.currentUser?.uid ?? '';
      final success = await VerificationService.approveVerification(
        verificationId: verification['id'] as String,
        reviewedBy: adminId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증이 승인되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVerifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 승인 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVerification(Map<String, dynamic> verification) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인증 거부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('거부 사유를 입력하세요:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '거부 사유',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('거부'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final adminId = AuthService.currentUser?.uid ?? '';
      final success = await VerificationService.rejectVerification(
        verificationId: verification['id'] as String,
        reviewedBy: adminId,
        reason: reasonController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증이 거부되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadVerifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 거부 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: const Text('인증 요청 검토', style: TextStyle(color: AppTheme.text)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.text),
            onPressed: _loadVerifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _verifications.isEmpty
          ? const Center(
              child: Text(
                '대기 중인 인증 요청이 없습니다.',
                style: TextStyle(color: AppTheme.sub),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _verifications.length,
              itemBuilder: (context, index) {
                final verification = _verifications[index];
                return Card(
                  color: AppTheme.card,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사용자 ID
                        Text(
                          '사용자 ID: ${verification['userId']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 인증 사진
                        if (verification['photoUrl'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedImage(
                              imageUrl: verification['photoUrl'] as String,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // 추가 정보
                        if (verification['additionalInfo'] != null &&
                            (verification['additionalInfo'] as String)
                                .isNotEmpty)
                          Text(
                            '추가 정보: ${verification['additionalInfo']}',
                            style: const TextStyle(color: AppTheme.sub),
                          ),
                        const SizedBox(height: 16),
                        // 승인/거부 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _rejectVerification(verification),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('거부'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _approveVerification(verification),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('승인'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
