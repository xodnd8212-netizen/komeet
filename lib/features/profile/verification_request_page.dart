import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../theme/theme.dart';
import '../../services/verification_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/cached_image.dart';

/// 프로필 인증 요청 페이지
class VerificationRequestPage extends StatefulWidget {
  const VerificationRequestPage({super.key});

  @override
  State<VerificationRequestPage> createState() =>
      _VerificationRequestPageState();
}

class _VerificationRequestPageState extends State<VerificationRequestPage> {
  Uint8List? _selectedImage;
  final _additionalInfoController = TextEditingController();
  bool _isSubmitting = false;
  String? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadVerificationStatus() async {
    final status = await VerificationService.getVerificationStatus();
    setState(() {
      _verificationStatus = status;
    });
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      if (result.files.first.bytes != null) {
        setState(() {
          _selectedImage = result.files.first.bytes!;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 실패: $e')));
    }
  }

  Future<void> _submitVerification() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 사진을 업로드해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 이미지 업로드
      final userId = VerificationService._firestore
          .collection('users')
          .doc()
          .id; // 임시 ID (실제로는 AuthService에서 가져와야 함)

      // StorageService를 통해 이미지 업로드
      final imageUrl = await StorageService.uploadProfileImage(_selectedImage!);
      if (imageUrl == null) {
        throw Exception('이미지 업로드 실패');
      }

      // 인증 요청 제출
      final success = await VerificationService.submitVerificationRequest(
        photoUrl: imageUrl,
        additionalInfo: _additionalInfoController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 요청이 제출되었습니다. 검토까지 1-2일 소요됩니다.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadVerificationStatus();
        Navigator.of(context).pop();
      } else {
        throw Exception('인증 요청 제출 실패');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 요청 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: const Text('프로필 인증', style: TextStyle(color: AppTheme.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 안내 문구
          Card(
            color: AppTheme.card,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '프로필 인증 안내',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• 본인 확인을 위한 사진을 업로드해주세요.\n'
                    '• 신분증 또는 본인 확인이 가능한 사진을 사용해주세요.\n'
                    '• 검토까지 1-2일이 소요됩니다.\n'
                    '• 인증된 프로필은 더 많은 매칭 기회를 얻을 수 있습니다.',
                    style: TextStyle(color: AppTheme.sub),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 현재 인증 상태
          if (_verificationStatus != null) ...[
            Card(
              color: _verificationStatus == 'approved'
                  ? Colors.green.withOpacity(0.1)
                  : _verificationStatus == 'rejected'
                  ? Colors.red.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _verificationStatus == 'approved'
                          ? Icons.check_circle
                          : _verificationStatus == 'rejected'
                          ? Icons.cancel
                          : Icons.pending,
                      color: _verificationStatus == 'approved'
                          ? Colors.green
                          : _verificationStatus == 'rejected'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _verificationStatus == 'approved'
                            ? '인증 완료'
                            : _verificationStatus == 'rejected'
                            ? '인증 거부됨'
                            : '검토 대기 중',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 인증 사진 업로드
          const Text(
            '인증 사진',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: AppTheme.sub,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '사진을 선택하세요',
                          style: TextStyle(color: AppTheme.sub),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // 추가 정보 (선택사항)
          const Text(
            '추가 정보 (선택사항)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _additionalInfoController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '본인 확인에 도움이 되는 추가 정보를 입력하세요.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.card,
            ),
            style: const TextStyle(color: AppTheme.text),
          ),
          const SizedBox(height: 32),

          // 제출 버튼
          ElevatedButton(
            onPressed: _isSubmitting || _verificationStatus == 'pending'
                ? null
                : _submitVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _verificationStatus == 'pending' ? '검토 대기 중' : '인증 요청 제출',
                  ),
          ),
        ],
      ),
    );
  }
}
