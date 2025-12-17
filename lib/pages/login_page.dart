import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.from});

  final String? from;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isBusy = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                    'ログイン',
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
                    autofillHints: const [AutofillHints.password],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'パスワードを入力してください';
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
                                  await auth.signInWithEmailAndPassword(
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
                                    SnackBar(content: Text('ログインに失敗しました: $e')),
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
                            : const Text('ログイン'),
                      ),
                      OutlinedButton(
                        onPressed: _isBusy
                            ? null
                            : () {
                                final from = widget.from;
                                final suffix =
                                    from == null || from.isEmpty ? '' : '?from=$from';
                                context.go('${CocoshibaPaths.signup}$suffix');
                              },
                        child: const Text('アカウント作成へ'),
                      ),
                      TextButton(
                        onPressed: _isBusy
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty || !email.contains('@')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('メールアドレスを入力してください')),
                                  );
                                  return;
                                }
                                setState(() => _isBusy = true);
                                try {
                                  await auth.sendPasswordResetEmail(email: email);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('パスワードリセットメールを送信しました')),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('送信に失敗しました: $e')),
                                  );
                                } finally {
                                  if (mounted) setState(() => _isBusy = false);
                                }
                              },
                        child: const Text('パスワードを忘れた場合'),
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
