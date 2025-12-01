import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/image_utils.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadProfileImage(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 이미지 형식 검증
      if (!ImageUtils.isValidImageFormat(bytes)) {
        throw Exception('지원하지 않는 이미지 형식입니다. (JPEG, PNG, WebP만 지원)');
      }

      // 이미지 크기 확인 및 리사이징
      Uint8List processedBytes = bytes;
      if (ImageUtils.isImageTooLarge(bytes, maxMB: 5.0)) {
        AppLogger.info('이미지 리사이징 시작', {
          'originalSize': ImageUtils.getImageSizeMB(bytes),
          'userId': userId,
        });
        final resized = await ImageUtils.resizeImage(bytes, maxWidth: 1080, maxHeight: 1080);
        if (resized != null) {
          processedBytes = resized;
          AppLogger.info('이미지 리사이징 완료', {
            'newSize': ImageUtils.getImageSizeMB(processedBytes),
            'userId': userId,
          });
        } else {
          AppLogger.warning('이미지 리사이징 실패, 원본 사용', {'userId': userId});
        }
      }

      // 최종 크기 확인 (10MB 제한)
      if (processedBytes.length > 10 * 1024 * 1024) {
        throw Exception('이미지 크기는 10MB 이하여야 합니다.');
      }

      final ref = _storage.ref().child('profiles/$userId/$fileName');
      final uploadTask = ref.putData(processedBytes);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      
      AppLogger.info('프로필 이미지 업로드 성공', {
        'userId': userId,
        'fileName': fileName,
        'size': ImageUtils.getImageSizeMB(processedBytes),
      });
      
      return url;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('이미지 업로드 실패 (Firebase)', e, stackTrace);
      throw Exception('이미지 업로드 실패: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.error('이미지 업로드 중 오류', e, stackTrace);
      throw Exception('이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  static Future<String?> uploadChatImage(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 이미지 형식 검증
      if (!ImageUtils.isValidImageFormat(bytes)) {
        throw Exception('지원하지 않는 이미지 형식입니다. (JPEG, PNG, WebP만 지원)');
      }

      // 채팅 이미지는 더 작게 리사이징 (최대 720px)
      Uint8List processedBytes = bytes;
      if (ImageUtils.isImageTooLarge(bytes, maxMB: 3.0)) {
        final resized = await ImageUtils.resizeImage(bytes, maxWidth: 720, maxHeight: 720);
        if (resized != null) {
          processedBytes = resized;
        }
      }

      // 최종 크기 확인 (5MB 제한 - 채팅은 더 작게)
      if (processedBytes.length > 5 * 1024 * 1024) {
        throw Exception('채팅 이미지 크기는 5MB 이하여야 합니다.');
      }

      final ref = _storage.ref().child('chat/$userId/$fileName');
      final uploadTask = ref.putData(processedBytes);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      
      AppLogger.info('채팅 이미지 업로드 성공', {
        'userId': userId,
        'fileName': fileName,
      });
      
      return url;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('채팅 이미지 업로드 실패 (Firebase)', e, stackTrace);
      throw Exception('이미지 업로드 실패: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.error('채팅 이미지 업로드 중 오류', e, stackTrace);
      throw Exception('이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  static Future<List<String>> uploadProfileImages(
    List<Uint8List> images,
  ) async {
    final urls = <String>[];
    final errors = <String>[];

    for (int i = 0; i < images.length; i++) {
      try {
        final fileName =
            'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await uploadProfileImage(images[i], fileName);
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        errors.add(
          '이미지 ${i + 1}: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }

    if (errors.isNotEmpty && urls.isEmpty) {
      throw Exception('모든 이미지 업로드에 실패했습니다.\n${errors.join('\n')}');
    }

    if (errors.isNotEmpty) {
      // 일부만 성공한 경우 경고는 하지만 계속 진행
      // 필요시 throw Exception('일부 이미지 업로드 실패: ${errors.join(', ')}');
    }

    return urls;
  }
}
