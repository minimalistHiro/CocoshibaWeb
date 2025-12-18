import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _AppHeader(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const _AppHeader();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final path = GoRouterState.of(context).uri.path;

    return AppBar(
      titleSpacing: 16,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;

          return Row(
            children: [
              InkWell(
                onTap: () => context.go(CocoshibaPaths.home),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/cocoshiba_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      storeDisplayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!isCompact) ...[
                _NavButton(
                  label: 'ホーム',
                  to: CocoshibaPaths.home,
                  isActive: path == CocoshibaPaths.home,
                ),
                _NavButton(
                  label: 'カレンダー',
                  to: CocoshibaPaths.calendar,
                  isActive: path.startsWith(CocoshibaPaths.calendar),
                ),
                _NavButton(
                  label: 'メニュー',
                  to: CocoshibaPaths.menu,
                  isActive: path.startsWith(CocoshibaPaths.menu),
                ),
                _NavButton(
                  label: '店舗情報',
                  to: CocoshibaPaths.store,
                  isActive: path.startsWith(CocoshibaPaths.store),
                ),
                const Spacer(),
              ] else ...[
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'メニュー',
                  onSelected: (value) => context.go(value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: CocoshibaPaths.home, child: Text('ホーム')),
                    PopupMenuItem(
                      value: CocoshibaPaths.calendar,
                      child: Text('カレンダー'),
                    ),
                    PopupMenuItem(
                        value: CocoshibaPaths.menu, child: Text('メニュー')),
                    PopupMenuItem(
                        value: CocoshibaPaths.store, child: Text('店舗情報')),
                  ],
                  icon: const Icon(Icons.menu),
                ),
              ],
              StreamBuilder(
                stream: auth.onAuthStateChanged,
                builder: (context, snapshot) {
                  final user = snapshot.data ?? auth.currentUser;
                  final isLoggedIn = user != null;

                  if (!isLoggedIn) {
                    if (isCompact) {
                      return PopupMenuButton<String>(
                        tooltip: 'アカウント',
                        onSelected: (value) => context.go(value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: CocoshibaPaths.signup,
                            child: Text('アカウント作成'),
                          ),
                          PopupMenuItem(
                              value: CocoshibaPaths.login, child: Text('ログイン')),
                        ],
                        icon: const Icon(Icons.person_outline),
                      );
                    }
                    return Row(
                      children: [
                        TextButton(
                          onPressed: () => context.go(CocoshibaPaths.signup),
                          child: const Text('アカウント作成'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => context.go(CocoshibaPaths.login),
                          child: const Text('ログイン'),
                        ),
                      ],
                    );
                  }

                  if (isCompact) {
                    return PopupMenuButton<String>(
                      tooltip: 'アカウント',
                      onSelected: (value) async {
                        if (value == 'logout') {
                          final confirmed = await _confirmSignOut(context);
                          if (confirmed != true) return;
                          await auth.signOut();
                          if (context.mounted) {
                            context.go(CocoshibaPaths.home);
                          }
                          return;
                        }
                        context.go(value);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: CocoshibaPaths.account,
                          child: Text('アカウント管理'),
                        ),
                        PopupMenuItem(value: 'logout', child: Text('ログアウト')),
                      ],
                      icon: const Icon(Icons.person),
                    );
                  }

                  return Row(
                    children: [
                      TextButton(
                        onPressed: () => context.go(CocoshibaPaths.account),
                        child: const Text('アカウント管理'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final confirmed = await _confirmSignOut(context);
                          if (confirmed != true) return;
                          await auth.signOut();
                          if (context.mounted) {
                            context.go(CocoshibaPaths.home);
                          }
                        },
                        child: const Text('ログアウト'),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.to,
    required this.isActive,
  });

  final String label;
  final String to;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => context.go(to),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? colorScheme.primary : null,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}
