import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
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

      // 파일 크기 확인 (10MB 제한)
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('이미지 크기는 10MB 이하여야 합니다.');
      }

      final ref = _storage.ref().child('profiles/$userId/$fileName');
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('이미지 업로드 실패: ${e.message}');
    } catch (e) {
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

      // 파일 크기 확인 (10MB 제한)
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('이미지 크기는 10MB 이하여야 합니다.');
      }

      final ref = _storage.ref().child('chat/$userId/$fileName');
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('이미지 업로드 실패: ${e.message}');
    } catch (e) {
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
