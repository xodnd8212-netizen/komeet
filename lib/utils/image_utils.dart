import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// 이미지 처리 유틸리티
class ImageUtils {
  /// 이미지 리사이징 (최대 크기 제한)
  static Future<Uint8List?> resizeImage(
    Uint8List imageBytes, {
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    try {
      // 이미지 디코딩
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // PNG로 인코딩 (JPEG는 품질 설정 불가)
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final resizedBytes = byteData.buffer.asUint8List();
      
      // 원본 이미지 해제
      image.dispose();

      return resizedBytes;
    } catch (e) {
      return null;
    }
  }

  /// 이미지 크기 확인 (MB)
  static double getImageSizeMB(Uint8List bytes) {
    return bytes.length / (1024 * 1024);
  }

  /// 이미지가 너무 큰지 확인
  static bool isImageTooLarge(Uint8List bytes, {double maxMB = 10.0}) {
    return getImageSizeMB(bytes) > maxMB;
  }

  /// 이미지 형식 확인
  static bool isValidImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return false;
    
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    
    // WebP: RIFF ... WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    
    return false;
  }
}

