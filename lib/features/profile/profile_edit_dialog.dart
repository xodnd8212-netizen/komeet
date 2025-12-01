import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../theme/theme.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../services/geo.dart';

class ProfileEditDialog extends StatefulWidget {
  final UserProfile? initialProfile;
  const ProfileEditDialog({super.key, this.initialProfile});

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _occupationController = TextEditingController();
  final List<Uint8List> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  double _maxDistance = 30;
  final List<String> _selectedInterests = [];
  final List<String> _selectedLanguages = [];
  final TextEditingController _newInterestController = TextEditingController();
  final TextEditingController _newLanguageController = TextEditingController();

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
      _selectedLanguages.addAll(['한국어', '일본어']); // 기본값
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    _newInterestController.dispose();
    _newLanguageController.dispose();
    super.dispose();
  }


  void _addInterest() {
    final interest = _newInterestController.text.trim();
    if (interest.isNotEmpty && !_selectedInterests.contains(interest)) {
      setState(() {
        _selectedInterests.add(interest);
        _newInterestController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _selectedInterests.remove(interest);
    });
  }

  void _addLanguage() {
    final language = _newLanguageController.text.trim();
    if (language.isNotEmpty && !_selectedLanguages.contains(language)) {
      setState(() {
        _selectedLanguages.add(language);
        _newLanguageController.clear();
      });
    }
  }

  void _removeLanguage(String language) {
    setState(() {
      _selectedLanguages.remove(language);
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

    List<String> photoUrls = List.from(_existingImageUrls);
    if (_selectedImages.isNotEmpty) {
      try {
        final uploadedUrls = await StorageService.uploadProfileImages(_selectedImages);
        photoUrls.addAll(uploadedUrls);
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    GeoPoint? location;
    try {
      location = await LocationService.getCurrentLocation();
    } catch (e) {
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
      Navigator.of(context).pop();
      if (savedId != null) {
        Navigator.of(context).pop(profile);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    '프로필 수정',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.sub),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '이름 *',
                          labelStyle: TextStyle(color: AppTheme.sub),
                        ),
                        style: const TextStyle(color: AppTheme.text),
                        validator: (v) => v?.isEmpty ?? true ? '이름을 입력하세요' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: '나이 *',
                          labelStyle: TextStyle(color: AppTheme.sub),
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
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: '도시 *',
                          labelStyle: TextStyle(color: AppTheme.sub),
                        ),
                        style: const TextStyle(color: AppTheme.text),
                        validator: (v) => v?.isEmpty ?? true ? '도시를 입력하세요' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _occupationController,
                        decoration: const InputDecoration(
                          labelText: '직업',
                          labelStyle: TextStyle(color: AppTheme.sub),
                          hintText: '예: 소프트웨어 개발자',
                        ),
                        style: const TextStyle(color: AppTheme.text),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: '자기소개 *',
                          labelStyle: TextStyle(color: AppTheme.sub),
                        ),
                        style: const TextStyle(color: AppTheme.text),
                        maxLines: 4,
                        validator: (v) => v?.isEmpty ?? true ? '자기소개를 입력하세요' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '언어',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedLanguages.map((lang) {
                          return Chip(
                            label: Text(lang),
                            onDeleted: () => _removeLanguage(lang),
                            deleteIcon: const Icon(Icons.close, size: 16),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newLanguageController,
                              decoration: const InputDecoration(
                                hintText: '언어 추가',
                                hintStyle: TextStyle(color: AppTheme.sub),
                              ),
                              style: const TextStyle(color: AppTheme.text),
                              onSubmitted: (_) => _addLanguage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _addLanguage,
                            child: const Text('추가'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '관심사',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedInterests.map((interest) {
                          return Chip(
                            label: Text(interest),
                            onDeleted: () => _removeInterest(interest),
                            deleteIcon: const Icon(Icons.close, size: 16),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newInterestController,
                              decoration: const InputDecoration(
                                hintText: '관심사 추가',
                                hintStyle: TextStyle(color: AppTheme.sub),
                              ),
                              style: const TextStyle(color: AppTheme.text),
                              onSubmitted: (_) => _addInterest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _addInterest,
                            child: const Text('추가'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: AppTheme.sub),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pink,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

