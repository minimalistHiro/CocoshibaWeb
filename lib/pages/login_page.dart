import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/widgets/google_sign_in_button.dart';
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

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'ログイン',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                GoogleSignInButton(
                  label: 'Googleでサインイン',
                  isBusy: _isBusy,
                  onPressed: () async {
                    setState(() => _isBusy = true);
                    try {
                      await auth.signInWithGoogle();
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
                        SnackBar(content: Text('Googleログインに失敗しました: $e')),
                      );
                    } finally {
                      if (mounted) setState(() => _isBusy = false);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('または'),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.go(CocoshibaPaths.passwordReset),
                    child: const Text('パスワードを忘れた方はこちら'),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
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
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: _isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('ログイン'),
                      ),
                    ),
                    const SizedBox(height: 128),
                    Text(
                      'まだアカウント作成されていない方は',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isBusy
                            ? null
                            : () {
                                final from = widget.from;
                                final suffix = from == null || from.isEmpty
                                    ? ''
                                    : '?from=$from';
                                context.go('${CocoshibaPaths.signup}$suffix');
                              },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('アカウント作成へ'),
                      ),
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
