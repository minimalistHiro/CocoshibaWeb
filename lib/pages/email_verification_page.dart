import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, this.email, this.from});

  final String? email;
  final String? from;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isResending = false;
  bool _isChecking = false;
  bool _didCheck = false;
  final UserProfileService _profileService = UserProfileService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didCheck) return;
    _didCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNextIfVerified());
  }

  String _displayEmail() {
    final auth = AppServices.of(context).auth;
    final currentEmail = auth.currentUser?.email ?? '';
    if (currentEmail.trim().isNotEmpty) return currentEmail.trim();
    return (widget.email ?? '').trim();
  }

  Future<void> _goNextIfVerified() async {
    final auth = AppServices.of(context).auth;
    final user = auth.currentUser;
    if (user == null || !user.emailVerified) return;

    await _profileService.updateEmailVerificationStatus(
      user.uid,
      emailVerified: true,
    );
    final from = widget.from;
    final suffix = from == null || from.isEmpty ? '' : '?from=$from';
    if (!mounted) return;
    context.go('${CocoshibaPaths.accountInfoRegister}$suffix');
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      final auth = AppServices.of(context).auth;
      await auth.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('確認メールを再送信しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('再送信に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final auth = AppServices.of(context).auth;
      await auth.reloadCurrentUser();
      final verified = auth.currentUser?.emailVerified ?? false;
      if (!mounted) return;
      if (verified) {
        await _goNextIfVerified();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メール認証がまだ完了していません')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('確認に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final user = auth.currentUser;

    if (user == null) {
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
                    'メール認証',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('ログイン情報が見つかりませんでした。'),
                const SizedBox(height: 24),
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
                    child: const Text('ログイン画面へ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final email = _displayEmail();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  'メールアドレスの確認',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '登録したメールアドレス宛に確認メールを送信しました。'
                'メール内のリンクをクリックして認証を完了してください。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('メールを再送信'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isChecking ? null : _checkVerification,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('認証完了したので続行'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
