/// 입력값 검증 유틸리티
class Validators {
  /// 이메일 검증
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  /// 비밀번호 검증
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }
    return null;
  }

  /// 이름 검증
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요.';
    }
    if (value.length < 2) {
      return '이름은 최소 2자 이상이어야 합니다.';
    }
    if (value.length > 50) {
      return '이름은 50자 이하여야 합니다.';
    }
    return null;
  }

  /// 나이 검증
  static String? age(int? value) {
    if (value == null) {
      return '나이를 입력해주세요.';
    }
    if (value < 18) {
      return '만 18세 이상만 가입할 수 있습니다.';
    }
    if (value > 100) {
      return '올바른 나이를 입력해주세요.';
    }
    return null;
  }

  /// 생년월일 기반 나이 검증
  /// [age]: 입력된 나이
  /// [birthDate]: 생년월일
  /// 반환: null이면 검증 통과, 아니면 에러 메시지
  static String? validateAgeWithBirthDate(int? age, DateTime? birthDate) {
    // 기본 나이 검증
    final ageError = Validators.age(age);
    if (ageError != null) {
      return ageError;
    }

    // 생년월일이 제공된 경우 추가 검증
    if (birthDate != null) {
      final today = DateTime.now();
      int calculatedAge = today.year - birthDate.year;

      // 생일이 아직 지나지 않았으면 1살 빼기
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        calculatedAge--;
      }

      // 계산된 나이가 18세 미만이면 차단
      if (calculatedAge < 18) {
        return '만 18세 이상만 가입할 수 있습니다. (생년월일 기준)';
      }

      // 입력된 나이와 계산된 나이가 2살 이상 차이나면 경고
      if ((calculatedAge - age!).abs() > 2) {
        return '입력하신 나이와 생년월일이 일치하지 않습니다. 다시 확인해주세요.';
      }
    }

    return null;
  }

  /// 자기소개 검증
  static String? bio(String? value) {
    if (value == null || value.isEmpty) {
      return '자기소개를 입력해주세요.';
    }
    if (value.length < 10) {
      return '자기소개는 최소 10자 이상이어야 합니다.';
    }
    if (value.length > 500) {
      return '자기소개는 500자 이하여야 합니다.';
    }
    return null;
  }

  /// 도시 검증
  static String? city(String? value) {
    if (value == null || value.isEmpty) {
      return '도시를 입력해주세요.';
    }
    if (value.length > 100) {
      return '도시명은 100자 이하여야 합니다.';
    }
    return null;
  }

  /// 관심사 검증
  static String? interests(List<String>? value) {
    if (value == null || value.isEmpty) {
      return '최소 1개의 관심사를 선택해주세요.';
    }
    if (value.length > 5) {
      return '관심사는 최대 5개까지 선택할 수 있습니다.';
    }
    return null;
  }

  /// 프로필 사진 검증
  static String? photos(List<String>? value) {
    if (value == null || value.isEmpty) {
      return '최소 1장의 프로필 사진을 업로드해주세요.';
    }
    if (value.length > 6) {
      return '프로필 사진은 최대 6장까지 업로드할 수 있습니다.';
    }
    return null;
  }

  /// 위치 좌표 검증
  static String? coordinates(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return '위치 정보를 허용해주세요.';
    }
    if (lat < -90 || lat > 90) {
      return '올바른 위도를 입력해주세요.';
    }
    if (lng < -180 || lng > 180) {
      return '올바른 경도를 입력해주세요.';
    }
    return null;
  }
}
