import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../services/geo.dart';
import '../../widgets/cached_image.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class ProfileEditPage extends StatefulWidget {
  final UserProfile? initialProfile;
  const ProfileEditPage({super.key, this.initialProfile});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final List<Uint8List> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  double _maxDistance = 30;
  final List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      final p = widget.initialProfile!;
      _nameController.text = p.name;
      _ageController.text = p.age.toString();
      _cityController.text = p.city;
      _bioController.text = p.bio;
      _maxDistance = p.maxDistanceKm;
      _selectedInterests.addAll(p.interests);
      _existingImageUrls.addAll(p.photoUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      if (_selectedImages.length + result.files.length > 6) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 6장까지 선택 가능합니다.')),
        );
        return;
      }
      setState(() {
        for (final file in result.files) {
          if (file.bytes != null) {
            _selectedImages.add(file.bytes!);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _existingImageUrls.length) {
        _existingImageUrls.removeAt(index);
      } else {
        _selectedImages.removeAt(index - _existingImageUrls.length);
      }
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 5) {
          _selectedInterests.add(interest);
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1장의 사진이 필요합니다.')),
      );
      return;
    }

    // 익명 로그인 (실제로는 이메일/소셜 로그인 사용)
    if (AuthService.currentUser == null) {
      await AuthService.signInAnonymously();
    }

    if (AuthService.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 이미지 업로드
    List<String> photoUrls = List.from(_existingImageUrls);
    if (_selectedImages.isNotEmpty) {
      try {
        final uploadedUrls = await StorageService.uploadProfileImages(_selectedImages);
        photoUrls.addAll(uploadedUrls);
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    // 위치 정보 가져오기
    GeoPoint? location;
    try {
      location = await LocationService.getCurrentLocation();
    } catch (e) {
      // 위치 정보를 가져올 수 없으면 기존 위치 유지 또는 null
      if (widget.initialProfile != null) {
        final existing = widget.initialProfile!;
        if (existing.lat != null && existing.lng != null) {
          location = GeoPoint(existing.lat!, existing.lng!);
        }
      }
    }

    final profile = UserProfile(
      id: widget.initialProfile?.id,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 0,
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      interests: _selectedInterests,
      maxDistanceKm: _maxDistance,
      photoUrls: photoUrls,
      lat: location?.lat,
      lng: location?.lng,
      updatedAt: DateTime.now(),
    );

    try {
      final savedId = await ProfileService.saveProfile(profile);
      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      if (savedId != null) {
        Navigator.of(context).pop(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필이 저장되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        title: const Text('프로필 편집', style: TextStyle(color: AppTheme.text)),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('저장', style: TextStyle(color: AppTheme.pink)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 사진 섹션
            Text('사진 (${_existingImageUrls.length + _selectedImages.length}/6)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _existingImageUrls.length + _selectedImages.length + (_existingImageUrls.length + _selectedImages.length < 6 ? 1 : 0),
                itemBuilder: (_, i) {
                  final totalImages = _existingImageUrls.length + _selectedImages.length;
                  if (i == totalImages) {
                    return _AddPhotoButton(onTap: _pickImage);
                  }
                  if (i < _existingImageUrls.length) {
                    return _PhotoPreview(
                      imageUrl: _existingImageUrls[i],
                      onRemove: () => _removeImage(i),
                    );
                  }
                  return _PhotoPreview(
                    image: _selectedImages[i - _existingImageUrls.length],
                    onRemove: () => _removeImage(i),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                labelStyle: TextStyle(color: AppTheme.sub),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: AppTheme.text),
              validator: (v) => v?.isEmpty ?? true ? '이름을 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            // 나이
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: '나이',
                labelStyle: TextStyle(color: AppTheme.sub),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: AppTheme.text),
              keyboardType: TextInputType.number,
              validator: (v) {
                final age = int.tryParse(v ?? '');
                if (age == null || age < 18 || age > 100) {
                  return '18-100 사이의 나이를 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 도시
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: '도시',
                labelStyle: TextStyle(color: AppTheme.sub),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: AppTheme.text),
              validator: (v) => v?.isEmpty ?? true ? '도시를 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            // 자기소개
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: '자기소개',
                labelStyle: TextStyle(color: AppTheme.sub),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: AppTheme.text),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? '자기소개를 입력하세요' : null,
            ),
            const SizedBox(height: 24),
            // 관심사
            Text('관심사 (${_selectedInterests.length}/5)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['K-pop', '여행', '요리', '영화', '운동', '독서', '게임', '음악'].map((interest) {
                final selected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: selected,
                  onSelected: (_) => _toggleInterest(interest),
                  selectedColor: AppTheme.pink.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.pink,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // 최대 거리
            Text('최대 거리: ${_maxDistance.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
            Slider(
              value: _maxDistance,
              min: 0.1,
              max: 200,
              divisions: 1999,
              label: '${_maxDistance.toStringAsFixed(1)} km',
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.line, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add_photo_alternate, color: AppTheme.sub, size: 32),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final Uint8List? image;
  final String? imageUrl;
  final VoidCallback onRemove;
  const _PhotoPreview({this.image, this.imageUrl, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.line),
          ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image != null
                  ? Image.memory(image!, fit: BoxFit.cover)
                  : imageUrl != null
                      ? CachedImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : const Icon(Icons.image),
            ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

