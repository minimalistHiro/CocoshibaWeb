import 'package:cocoshibaweb/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class LoginInfoUpdatePage extends StatefulWidget {
  const LoginInfoUpdatePage({super.key});

  @override
  State<LoginInfoUpdatePage> createState() => _LoginInfoUpdatePageState();
}

class _LoginInfoUpdatePageState extends State<LoginInfoUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUpdating = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final auth = AppServices.of(context).auth;
    _emailController.text = auth.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateLoginInfo() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();

    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase が初期化されていません。')),
      );
      return;
    }

    final auth = AppServices.of(context).auth;
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です。')),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await auth.updateLoginInfo(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログイン情報を更新しました')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログイン情報の更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ログイン情報変更',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      helperText: 'メールアドレスは変更できません',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: '現在のパスワード',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrentPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _showCurrentPassword = !_showCurrentPassword,
                        ),
                      ),
                    ),
                    obscureText: !_showCurrentPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '現在のパスワードを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _showNewPassword = !_showNewPassword,
                        ),
                      ),
                    ),
                    obscureText: !_showNewPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '新しいパスワードを入力してください';
                      }
                      if (value.length < 6) {
                        return '6文字以上で入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード（確認）',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                      ),
                    ),
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      final newPassword = _newPasswordController.text;
                      if (value != newPassword) {
                        return '新しいパスワードが一致しません';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isUpdating ? null : _updateLoginInfo,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isUpdating ? '更新中...' : '保存する'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

