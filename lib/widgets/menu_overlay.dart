import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/widgets/store_info_card.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({
    super.key,
    required this.fade,
    required this.slide,
    required this.onClose,
    required this.onNavigate,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;
  final VoidCallback onClose;
  final Future<void> Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    Widget menuButton(_MenuLink link) {
      return TextButton(
        onPressed: () async {
          await onNavigate(link.path);
        },
        style: TextButton.styleFrom(
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(44),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        child: Text(link.label),
      );
    }

    Future<void> open(Uri uri) async {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Positioned.fill(
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: Material(
            color: cocoshibaMainColor,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: '閉じる',
                          onPressed: onClose,
                          icon: Icon(Icons.close, color: onPrimary),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _menuLinks.map(menuButton).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Instagram',
                              onPressed: () => open(storeInstagramUri),
                              icon: Image.asset(
                                'assets/images/Instagram.png',
                                width: 28,
                                height: 28,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Facebook',
                              onPressed: () => open(storeFacebookUri),
                              icon: Image.asset(
                                'assets/images/facebook.png',
                                width: 28,
                                height: 28,
                              ),
                            ),
                            IconButton(
                              tooltip: 'X',
                              onPressed: () => open(storeXUri),
                              icon: Image.asset(
                                'assets/images/X.png',
                                width: 28,
                                height: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuLink {
  const _MenuLink(this.label, this.path);

  final String label;
  final String path;
}

const List<_MenuLink> _menuLinks = [
  _MenuLink('HOME', CocoshibaPaths.home),
  _MenuLink('EVENTS', CocoshibaPaths.events),
  _MenuLink('CALENDAR', CocoshibaPaths.calendar),
  _MenuLink('MENU', CocoshibaPaths.menu),
  _MenuLink('BOOK ORDER', CocoshibaPaths.bookOrder),
  _MenuLink('ACCESS', CocoshibaPaths.store),
];
