import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, this.from});

  final String? from;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isBusy = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'アカウント作成',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'メールアドレスを入力してください';
                      if (!v.contains('@')) return 'メールアドレスの形式が正しくありません';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      border: const OutlineInputBorder(),
                      helperText: '8文字以上推奨',
                      suffixIcon: IconButton(
                        tooltip: _isPasswordVisible ? '非表示' : '表示',
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'パスワードを入力してください';
                      if (v.length < 6) return 'パスワードは6文字以上にしてください';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordConfirmController,
                    decoration: InputDecoration(
                      labelText: 'パスワード（確認）',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _isPasswordConfirmVisible ? '非表示' : '表示',
                        onPressed: () => setState(
                          () => _isPasswordConfirmVisible = !_isPasswordConfirmVisible,
                        ),
                        icon: Icon(
                          _isPasswordConfirmVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    obscureText: !_isPasswordConfirmVisible,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '確認用パスワードを入力してください';
                      if (v != _passwordController.text) return 'パスワードが一致しません';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: _isBusy
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _isBusy = true);
                                try {
                                  await auth.signUpWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );
                                  if (!context.mounted) return;
                                  final from = widget.from;
                                  if (from != null && from.isNotEmpty) {
                                    context.go(Uri.decodeComponent(from));
                                  } else {
                                    context.go(CocoshibaPaths.home);
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('作成に失敗しました: $e')),
                                  );
                                } finally {
                                  if (mounted) setState(() => _isBusy = false);
                                }
                              },
                        child: _isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('作成する'),
                      ),
                      OutlinedButton(
                        onPressed: _isBusy
                            ? null
                            : () {
                                final from = widget.from;
                                final suffix =
                                    from == null || from.isEmpty ? '' : '?from=$from';
                                context.go('${CocoshibaPaths.login}$suffix');
                              },
                        child: const Text('ログインへ'),
                      ),
                    ],
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
