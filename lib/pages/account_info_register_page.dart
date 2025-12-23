import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/models/local_image.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/user_profile_service.dart';
import 'package:cocoshibaweb/utils/platform_image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountInfoRegisterPage extends StatefulWidget {
  const AccountInfoRegisterPage({super.key, this.from});

  final String? from;

  @override
  State<AccountInfoRegisterPage> createState() => _AccountInfoRegisterPageState();
}

class _AccountInfoRegisterPageState extends State<AccountInfoRegisterPage> {
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
      final name =
          ((profile?['name'] as String?) ?? user.displayName ?? '').trim();
      final bio = ((profile?['bio'] as String?) ?? '').trim();
      final ageGroup = (profile?['ageGroup'] as String?)?.trim();
      final area = (profile?['area'] as String?)?.trim();
      final gender = (profile?['gender'] as String?)?.trim();
      final photoUrl =
          ((profile?['photoUrl'] as String?) ?? user.photoUrl ?? '').trim();

      final hasProfile = name.isNotEmpty &&
          name != '未設定' &&
          (ageGroup ?? '').isNotEmpty &&
          (area ?? '').isNotEmpty &&
          (gender ?? '').isNotEmpty;
      if (hasProfile) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
        return;
      }

      if (!mounted) return;
      _nameController.text = name == '未設定' ? '' : name;
      _bioController.text = bio;
      setState(() {
        _selectedAgeGroup = ageGroup?.isNotEmpty == true ? ageGroup : null;
        _selectedArea = area?.isNotEmpty == true ? area : null;
        _selectedGender =
            gender?.isNotEmpty == true ? gender : (_selectedGender ?? '未回答');
        _currentPhotoUrl = photoUrl.isEmpty ? null : photoUrl;
        _selectedImage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'アカウント情報の取得に失敗しました。';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

      await auth.updateUserProfile(
        displayName: name,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウント情報を登録しました')),
      );
      _goNext();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アカウント情報の登録に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goNext() {
    final from = widget.from;
    if (from != null && from.isNotEmpty) {
      context.go(Uri.decodeComponent(from));
      return;
    }
    context.go(CocoshibaPaths.home);
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
                    'アカウント情報登録',
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
    final avatarImage = _avatarImage();

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
                  'アカウント情報登録',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'プロフィール情報を入力すると、サービスをスムーズに利用できます。',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundImage: avatarImage,
                      onForegroundImageError:
                          avatarImage == null ? null : (_, __) {},
                      child: avatarImage == null
                          ? Icon(
                              Icons.camera_alt_outlined,
                              size: 28,
                              color: theme.colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                (_isSaving || _isPickingImage) ? null : _pickImage,
                            icon: _isPickingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload),
                            label: const Text('写真を選択'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'プロフィール画像は任意です。',
                            style: theme.textTheme.bodySmall,
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _bioController,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: '自己紹介',
                    alignLabelWithHint: true,
                    hintText: '趣味や好きなことを書いてみましょう',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
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
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isSaving ? '登録中...' : '登録を完了する'),
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
