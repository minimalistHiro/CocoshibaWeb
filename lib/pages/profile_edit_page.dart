import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/models/local_image.dart';
import 'package:cocoshibaweb/services/user_profile_service.dart';
import 'package:cocoshibaweb/utils/platform_image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final UserProfileService _profileService = UserProfileService();
  final PlatformImagePicker _imagePicker = createPlatformImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  String? _loadError;
  String? _selectedAgeGroup;
  String? _selectedArea;
  String? _selectedGender;
  bool _didLoad = false;
  bool _removePhoto = false;
  LocalImage? _selectedImage;
  String? _currentPhotoUrl;

  final _ageGroups = const [
    '10代以下',
    '20代',
    '30代',
    '40代',
    '50代',
    '60代以上',
  ];

  final _areas = const [
    '川口市',
    '蕨市',
    'さいたま市',
    '戸田市',
    'その他県内',
    '県外',
  ];

  final _genders = const [
    '男性',
    '女性',
    '未回答',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (Firebase.apps.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'Firebase が初期化されていません。';
      });
      return;
    }

    final auth = AppServices.of(context).auth;
    final user = auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'ログインが必要です。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await _profileService.fetchProfile(user.uid);

      final fallbackName = (user.displayName ?? '').trim();
      final name = ((profile?['name'] as String?) ?? fallbackName).trim();
      final bio = ((profile?['bio'] as String?) ?? '').trim();
      final ageGroup = (profile?['ageGroup'] as String?)?.trim();
      final area = (profile?['area'] as String?)?.trim();
      final gender = (profile?['gender'] as String?)?.trim();
      final photoUrl =
          ((profile?['photoUrl'] as String?) ?? user.photoUrl ?? '').trim();

      if (!mounted) return;

      _nameController.text = name;
      _bioController.text = bio;
      setState(() {
        _selectedAgeGroup = ageGroup;
        _selectedArea = area;
        _selectedGender = gender?.isNotEmpty == true ? gender : '未回答';
        _currentPhotoUrl = photoUrl.isEmpty ? null : photoUrl;
        _selectedImage = null;
        _removePhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'プロフィールの取得に失敗しました。再試行してください。';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _initialLetter() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return '？';
    return text.substring(0, 1);
  }

  ImageProvider? _avatarImage() {
    if (_selectedImage != null) {
      return MemoryImage(_selectedImage!.bytes);
    }
    final url = (_currentPhotoUrl ?? '').trim();
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }

  Future<void> _pickImage() async {
    if (_isSaving || _isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picked = await _imagePicker.pickMultiImage();
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _selectedImage = picked.first;
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (Firebase.apps.isEmpty) return;

    final auth = AppServices.of(context).auth;
    final user = auth.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedAgeGroup == null || _selectedAgeGroup!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('年代を選択してください')),
      );
      return;
    }
    if (_selectedArea == null || _selectedArea!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('住所を選択してください')),
      );
      return;
    }
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('性別を選択してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final bio = _bioController.text.trim();
      String? photoUrl;

      if (_selectedImage != null) {
        photoUrl = await _profileService.uploadProfileImage(
          user.uid,
          _selectedImage!,
        );
      } else if (_removePhoto) {
        photoUrl = '';
      } else {
        photoUrl = _currentPhotoUrl;
      }

      await _profileService.upsertProfile(
        user.uid,
        name: name,
        ageGroup: _selectedAgeGroup!,
        area: _selectedArea!,
        gender: _selectedGender!,
        bio: bio,
        photoUrl: (photoUrl ?? '').trim().isEmpty ? null : photoUrl,
      );

      String? authPhotoUrl;
      if (_removePhoto) {
        authPhotoUrl = '';
      } else if (_selectedImage != null) {
        authPhotoUrl = photoUrl;
      }

      await auth.updateUserProfile(
        displayName: name,
        photoUrl: authPhotoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを更新しました')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プロフィールの更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プロフィール編集',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(_loadError!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadProfile,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'プロフィール編集',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final avatarImage = _avatarImage();
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundImage: avatarImage,
                          onForegroundImageError:
                              avatarImage == null ? null : (_, __) {},
                          child: avatarImage == null
                              ? Text(
                                  _initialLetter(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: (_isSaving || _isPickingImage)
                                ? null
                                : _pickImage,
                            icon: _isPickingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload),
                            label: const Text('画像をアップロード'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: (_isSaving ||
                                    _isPickingImage ||
                                    (_selectedImage == null &&
                                        (_currentPhotoUrl ?? '').isEmpty))
                                ? null
                                : () {
                                    setState(() {
                                      _selectedImage = null;
                                      _currentPhotoUrl = null;
                                      _removePhoto = true;
                                    });
                                  },
                            child: const Text('画像を削除'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名前',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '名前を入力してください';
                    }
                    if (value.trim().length > 40) {
                      return '40文字以内で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: '性別',
                    border: OutlineInputBorder(),
                  ),
                  items: _genders
                      .map(
                        (gender) => DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _selectedGender = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '性別を選択してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedAgeGroup,
                  decoration: const InputDecoration(
                    labelText: '年代',
                    border: OutlineInputBorder(),
                  ),
                  items: _ageGroups
                      .map(
                        (age) => DropdownMenuItem<String>(
                          value: age,
                          child: Text(age),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _selectedAgeGroup = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '年代を選択してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                    labelText: '住所',
                    border: OutlineInputBorder(),
                  ),
                  items: _areas
                      .map(
                        (area) => DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _selectedArea = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '住所を選択してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _bioController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: '自己紹介',
                    alignLabelWithHint: true,
                    hintText: '趣味や好きなことを書いてみましょう',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('保存する'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
