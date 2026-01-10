import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/owner_service.dart';
import 'package:cocoshibaweb/widgets/menu_overlay.dart';
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

Future<void> _showAccountItemsDialog(
  BuildContext context, {
  required AuthUser user,
}) {
  final rootContext = context;
  final auth = AppServices.of(context).auth;
  final ownerService = OwnerService();
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final name = (user.displayName ?? '').trim();
  final email = (user.email ?? '').trim();
  final headerLabel =
      name.isNotEmpty ? name : (email.isNotEmpty ? email : 'アカウント');

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
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: titleColor == null ? null : TextStyle(color: titleColor),
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: Text(headerLabel),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (!user.isGoogleSignIn)
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
              linkItem(
                Icons.privacy_tip_outlined,
                'データとプライバシー',
                subtitle: 'データの確認・エクスポート・削除',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  rootContext.go(CocoshibaPaths.dataPrivacy);
                },
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
              linkItem(
                Icons.article_outlined,
                '利用規約',
                subtitle: 'サービス利用のルール',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  rootContext.go(CocoshibaPaths.terms);
                },
              ),
              linkItem(
                Icons.privacy_tip_outlined,
                'プライバシーポリシー',
                subtitle: '個人情報の取り扱い',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  rootContext.go(CocoshibaPaths.privacyPolicy);
                },
              ),
              StreamBuilder<bool>(
                stream: ownerService.watchIsOwner(user),
                builder: (context, snapshot) {
                  final isOwner = snapshot.data == true;

                  if (!isOwner) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        linkItem(
                          Icons.logout,
                          'ログアウト',
                          titleColor: colorScheme.error,
                          iconColor: colorScheme.error,
                          onTap: () async {
                            Navigator.of(dialogContext).pop();
                            final confirmed = await _confirmSignOut(rootContext);
                            if (confirmed != true) return;
                            await auth.signOut();
                            if (rootContext.mounted) {
                              rootContext.go(CocoshibaPaths.home);
                            }
                          },
                        ),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      sectionHeader('管理者設定（管理者のみ）'),
                      item(Icons.support_agent_outlined, 'ユーザーチャットサポート',
                          subtitle: 'ユーザーとのチャット履歴を確認'),
                      item(Icons.dashboard_customize_outlined, 'ホーム画面編集',
                          subtitle: 'ホームのページを追加・整理'),
                      item(Icons.local_offer_outlined, 'キャンペーン編集',
                          subtitle: '掲載・開催期間を管理'),
                      item(Icons.event_busy_outlined, '定休日設定',
                          subtitle: '休業日をカレンダーで管理'),
                      item(Icons.admin_panel_settings_outlined, 'オーナー設定',
                          subtitle: 'ポイント還元率・店舗情報の管理'),
                      item(Icons.restaurant_menu_outlined, 'メニュー管理',
                          subtitle: 'メニュー一覧の編集・追加'),
                      item(Icons.edit_calendar_outlined, '既存イベント編集',
                          subtitle: '公開済みイベントの内容を変更'),
                      const SizedBox(height: 8),
                      linkItem(
                        Icons.logout,
                        'ログアウト',
                        titleColor: colorScheme.error,
                        iconColor: colorScheme.error,
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          final confirmed =
                              await _confirmSignOut(rootContext);
                          if (confirmed != true) return;
                          await auth.signOut();
                          if (rootContext.mounted) {
                            rootContext.go(CocoshibaPaths.home);
                          }
                        },
                      ),
                      item(Icons.delete_forever, 'アカウント削除'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
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

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  late final Animation<double> _menuFade;
  late final Animation<Offset> _menuSlide;
  bool _isMenuVisible = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _menuFade = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _menuController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _openMenu() async {
    if (_isMenuVisible) return;
    setState(() => _isMenuVisible = true);
    await _menuController.forward();
  }

  Future<void> _closeMenu() async {
    if (!_isMenuVisible) return;
    await _menuController.reverse();
    if (!mounted) return;
    setState(() => _isMenuVisible = false);
  }

  Future<void> _toggleMenu() async {
    if (_isMenuVisible) {
      await _closeMenu();
    } else {
      await _openMenu();
    }
  }

  Future<void> _navigateFromMenu(String path) async {
    await _closeMenu();
    if (!mounted) return;
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _AppHeader(
            onMenuPressed: _toggleMenu,
            menuProgress: _menuController,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: widget.child,
              ),
            ),
          ),
        ),
        if (_isMenuVisible)
          MenuOverlay(
            fade: _menuFade,
            slide: _menuSlide,
            onClose: _closeMenu,
            onNavigate: _navigateFromMenu,
          ),
      ],
    );
  }
}

class _AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const _AppHeader({
    required this.onMenuPressed,
    required this.menuProgress,
  });

  final VoidCallback onMenuPressed;
  final Animation<double> menuProgress;

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
                                    fontSize: 13,
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
                IconButton(
                  tooltip: 'メニュー',
                  onPressed: onMenuPressed,
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: menuProgress,
                  ),
                ),
              ],
              StreamBuilder(
                stream: auth.onAuthStateChanged,
                builder: (context, snapshot) {
                  final user = snapshot.data ?? auth.currentUser;
                  final isLoggedIn = user != null;

                  if (!isLoggedIn) {
                    if (isCompact) {
                      return IconButton(
                        tooltip: 'ログイン',
                        onPressed: () => context.go(CocoshibaPaths.login),
                        padding: const EdgeInsets.symmetric(horizontal: 1),
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
                          tooltip: 'アカウント',
                          onPressed: () =>
                              _showAccountItemsDialog(context, user: user),
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          icon: _buildUserAvatar(user),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      IconButton(
                        tooltip: 'アカウント',
                        onPressed: () =>
                            _showAccountItemsDialog(context, user: user),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
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
