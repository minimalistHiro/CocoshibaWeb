import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({
    super.key,
    this.oobCode,
    this.mode,
  });

  final String? oobCode;
  final String? mode;

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isBusy = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _hasVerifiedCode = false;
  bool _resetCompleted = false;
  String? _verifiedEmail;
  String? _errorMessage;

  bool get _hasCode => widget.oobCode != null && widget.oobCode!.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasCode && !_hasVerifiedCode) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final auth = AppServices.of(context).auth;
      final email =
          await auth.verifyPasswordResetCode(code: widget.oobCode!.trim());
      if (!mounted) return;
      setState(() {
        _verifiedEmail = email;
        _hasVerifiedCode = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'リンクが無効か期限切れです。もう一度再設定を行ってください。';
        _hasVerifiedCode = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _sendResetEmail() async {
    if (!_requestFormKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final auth = AppServices.of(context).auth;
      final continueUri =
          Uri.parse(Uri.base.origin).resolve(CocoshibaPaths.passwordReset);
      await auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
        continueUrl: continueUri.toString(),
      );
      if (!mounted) return;
      if (!mounted) return;
      final email = _emailController.text.trim();
      context.go('${CocoshibaPaths.passwordResetSent}?email=$email');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '送信に失敗しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _confirmReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final auth = AppServices.of(context).auth;
      await auth.confirmPasswordReset(
        code: widget.oobCode!.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _resetCompleted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '再設定に失敗しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final isResetMode = mode == null || mode == 'resetPassword';
    final showResetForm = _hasCode && isResetMode;
    final showRequestForm = !_hasCode || !isResetMode;
    final canReset = showResetForm && _errorMessage == null;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  'パスワード再設定',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (showRequestForm) ...[
                Form(
                  key: _requestFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '登録したメールアドレスを入力してください。',
                        style: textTheme.bodyMedium,
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
                          if (v == null || v.trim().isEmpty) {
                            return 'メールアドレスを入力してください';
                          }
                          if (!v.contains('@')) return 'メールアドレスの形式が正しくありません';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _isBusy ? null : _sendResetEmail,
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
                              : const Text('再設定メールを送信'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (showResetForm && _errorMessage != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(CocoshibaPaths.passwordReset),
                  child: const Text('再設定メールの送信へ戻る'),
                ),
              ],
              if (canReset) ...[
                if (_verifiedEmail != null) ...[
                  Text(
                    '対象メール: $_verifiedEmail',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_isBusy && !_resetCompleted)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_resetCompleted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'パスワードを再設定しました。',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () => context.go(CocoshibaPaths.login),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('ログインへ戻る'),
                        ),
                      ),
                    ],
                  )
                else
                  Form(
                    key: _resetFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: '新しいパスワード',
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
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'パスワードを入力してください';
                            }
                            if (v.length < 6) {
                              return 'パスワードは6文字以上にしてください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordConfirmController,
                          decoration: InputDecoration(
                            labelText: '新しいパスワード（確認）',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip:
                                  _isPasswordConfirmVisible ? '非表示' : '表示',
                              onPressed: () => setState(
                                () => _isPasswordConfirmVisible =
                                    !_isPasswordConfirmVisible,
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
                            if (v == null || v.isEmpty) {
                              return '確認用パスワードを入力してください';
                            }
                            if (v != _passwordController.text) {
                              return 'パスワードが一致しません';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _isBusy ? null : _confirmReset,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('パスワードを再設定'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
