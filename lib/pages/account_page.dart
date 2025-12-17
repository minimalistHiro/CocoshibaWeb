import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;

    return StreamBuilder(
      stream: auth.onAuthStateChanged,
      builder: (context, snapshot) {
        final user = snapshot.data ?? auth.currentUser;
        if (user == null) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'アカウント管理',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text('ログインが必要です。'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.go(CocoshibaPaths.login),
                        child: const Text('ログイン'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final email = user.email ?? '';

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'アカウント管理',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('メールアドレス',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        SelectableText(email.isEmpty ? '(未設定)' : email),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton(
                              onPressed: email.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        await auth.sendPasswordResetEmail(
                                            email: email);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('パスワードリセットメールを送信しました'),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('送信に失敗しました: $e')),
                                        );
                                      }
                                    },
                              child: const Text('パスワードリセット'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                final confirmed =
                                    await _confirmSignOut(context);
                                if (confirmed != true) return;
                                await auth.signOut();
                                if (context.mounted) {
                                  context.go(CocoshibaPaths.home);
                                }
                              },
                              child: const Text('ログアウト'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '退会（アカウント削除）',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '削除すると元に戻せません。Firebase Auth のユーザーが削除されます。',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () async {
                            final confirmed = await _confirmDelete(context);
                            if (confirmed != true) return;

                            try {
                              await auth.deleteAccount();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('アカウントを削除しました')),
                              );
                              context.go(CocoshibaPaths.home);
                            } catch (e) {
                              if (!context.mounted) return;
                              final password =
                                  await _reauthenticatePassword(context);
                              if (password == null) return;
                              try {
                                await auth.deleteAccount(
                                    passwordForReauth: password);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('アカウントを削除しました')),
                                );
                                context.go(CocoshibaPaths.home);
                              } catch (e2) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('削除に失敗しました: $e2')),
                                );
                              }
                            }
                          },
                          child: const Text('退会する'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退会しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('再度ログインが必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  Future<String?> _reauthenticatePassword(BuildContext context) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('再ログインが必要です'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '現在のパスワード',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('続行'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
