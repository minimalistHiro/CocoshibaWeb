import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/user_profile_service.dart';
import 'package:firebase_core/firebase_core.dart';
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

bool _isOwnerProfile(Map<String, dynamic>? profile) {
  if (profile == null) return false;

  final isOwner = profile['isOwner'];
  if (isOwner is bool) return isOwner;

  final owner = profile['owner'];
  if (owner is bool) return owner;

  final role = profile['role'];
  if (role is String) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'owner' || normalized == 'オーナー') return true;
  }

  return false;
}

Future<void> _showAccountItemsDialog(
  BuildContext context, {
  required AuthUser user,
}) {
  final rootContext = context;
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final name = (user.displayName ?? '').trim();
  final email = (user.email ?? '').trim();
  final headerLabel =
      name.isNotEmpty ? name : (email.isNotEmpty ? email : 'アカウント');
  final canReadProfile = Firebase.apps.isNotEmpty;
  final profileFuture = canReadProfile
      ? UserProfileService().fetchProfile(user.uid)
      : Future<Map<String, dynamic>?>.value(null);

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        title,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget item(IconData icon, String title, {String? subtitle}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      enabled: false,
    );
  }

  Widget linkItem(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => FutureBuilder<Map<String, dynamic>?>(
      future: profileFuture,
      builder: (context, snapshot) {
        final isOwner = canReadProfile && _isOwnerProfile(snapshot.data);
        final children = <Widget>[
          sectionHeader('アカウント設定'),
          linkItem(
            Icons.person_outline,
            'プロフィール編集',
            subtitle: '名前・アイコン・自己紹介を編集',
            onTap: () {
              Navigator.of(dialogContext).pop();
              rootContext.go(CocoshibaPaths.profileEdit);
            },
          ),
          linkItem(
            Icons.lock_outline,
            'ログイン情報変更',
            subtitle: 'パスワードを更新',
            onTap: () {
              Navigator.of(dialogContext).pop();
              rootContext.go(CocoshibaPaths.loginInfoUpdate);
            },
          ),
          sectionHeader('データとサポート'),
          item(
            Icons.privacy_tip_outlined,
            'データとプライバシー',
            subtitle: 'データの確認・エクスポート・削除',
          ),
          linkItem(
            Icons.help_outline,
            'サポート・ヘルプ',
            subtitle: 'お問い合わせ・FAQ・ポリシー',
            onTap: () {
              Navigator.of(dialogContext).pop();
              rootContext.go(CocoshibaPaths.supportHelp);
            },
          ),
        ];

        if (isOwner) {
          children.addAll([
            sectionHeader('管理者設定（管理者のみ）'),
            linkItem(
              Icons.support_agent_outlined,
              'ユーザーチャットサポート',
              subtitle: 'ユーザーとのチャット履歴を確認',
              onTap: () {
                Navigator.of(dialogContext).pop();
                rootContext.go(CocoshibaPaths.adminChat);
              },
            ),
            linkItem(
              Icons.event_busy_outlined,
              '定休日設定',
              subtitle: '休業日をカレンダーで管理',
              onTap: () {
                Navigator.of(dialogContext).pop();
                rootContext.go(CocoshibaPaths.adminClosedDays);
              },
            ),
            linkItem(
              Icons.admin_panel_settings_outlined,
              'オーナー設定',
              subtitle: 'ポイント還元率・店舗情報の管理',
              onTap: () {
                Navigator.of(dialogContext).pop();
                rootContext.go(CocoshibaPaths.adminOwnerSettings);
              },
            ),
            linkItem(
              Icons.restaurant_menu_outlined,
              'メニュー編集',
              subtitle: 'メニュー一覧の編集・追加',
              onTap: () {
                Navigator.of(dialogContext).pop();
                rootContext.go(CocoshibaPaths.adminMenu);
              },
            ),
            linkItem(
              Icons.edit_calendar_outlined,
              '既存イベント編集',
              subtitle: '公開済みイベントの内容を変更',
              onTap: () {
                Navigator.of(dialogContext).pop();
                rootContext.go(CocoshibaPaths.adminExistingEvents);
              },
            ),
          ]);
        }

        children.add(const SizedBox(height: 8));

        return AlertDialog(
          title: Text(headerLabel),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildUserAvatar(AuthUser user, {double radius = 16}) {
  final photoUrl = (user.photoUrl ?? '').trim();

  if (photoUrl.isNotEmpty) {
    return CircleAvatar(
      radius: radius,
      foregroundImage: NetworkImage(photoUrl),
      backgroundColor: Colors.grey.shade200,
      onForegroundImageError: (_, __) {},
      child: Icon(Icons.person_outline, size: radius * 1.2),
    );
  }

  return CircleAvatar(
    radius: radius,
    child: Icon(Icons.person_outline, size: radius * 1.2),
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
          // 画面幅を狭めた時にナビゲーションがオーバーフローしやすいので、
          // 余裕を持って早めにコンパクト表示へ切り替える。
          // メニュー項目追加時にオーバーフローしやすいため、閾値はやや広めに取る。
          final isCompact = constraints.maxWidth < 1180;

          return Row(
            children: [
              InkWell(
                onTap: () => context.go(CocoshibaPaths.home),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // Row の子は横方向が unbounded になりやすいので、
                        // 明示的に最大幅を持たせて縮小表示できるようにする。
                        maxWidth: isCompact ? 260 : 340,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          storeDisplayName,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
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
                  label: 'イベント',
                  to: CocoshibaPaths.events,
                  isActive: path.startsWith(CocoshibaPaths.events),
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
                  label: '本の注文',
                  to: CocoshibaPaths.bookOrder,
                  isActive: path.startsWith(CocoshibaPaths.bookOrder),
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
                      value: CocoshibaPaths.events,
                      child: Text('イベント'),
                    ),
                    PopupMenuItem(
                      value: CocoshibaPaths.calendar,
                      child: Text('カレンダー'),
                    ),
                    PopupMenuItem(
                        value: CocoshibaPaths.menu, child: Text('メニュー')),
                    PopupMenuItem(
                        value: CocoshibaPaths.bookOrder, child: Text('本の注文')),
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
                    return Row(
                      children: [
                        IconButton(
                          tooltip: 'ログアウト',
                          onPressed: () async {
                            final confirmed = await _confirmSignOut(context);
                            if (confirmed != true) return;
                            await auth.signOut();
                            if (context.mounted) {
                              context.go(CocoshibaPaths.home);
                            }
                          },
                          icon: const Icon(Icons.logout),
                        ),
                        IconButton(
                          tooltip: 'アカウント',
                          onPressed: () =>
                              _showAccountItemsDialog(context, user: user),
                          icon: _buildUserAvatar(user),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
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
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'アカウント',
                        onPressed: () =>
                            _showAccountItemsDialog(context, user: user),
                        icon: _buildUserAvatar(user),
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
