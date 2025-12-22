import 'package:cocoshibaweb/models/menu_item.dart';
import 'package:cocoshibaweb/services/menu_service.dart';
import 'package:cocoshibaweb/widgets/cocoshiba_network_image.dart';
import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuService _menuService = MenuService();
  late Stream<List<MenuItem>> _menusStream;

  @override
  void initState() {
    super.initState();
    _menusStream = _menuService.watchMenus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<MenuCategory> get _categoryOrder => const [
        MenuCategory.food,
        MenuCategory.drink,
        MenuCategory.beer,
      ];

  void _reloadMenus() {
    setState(() {
      _menusStream = _menuService.watchMenus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            'メニュー',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: _menusStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ErrorState(
                  onRetry: _reloadMenus,
                  message: snapshot.error.toString(),
                );
              }

              final menus = snapshot.data ?? [];
              if (menus.isEmpty) {
                return const _EmptyState(
                  icon: Icons.restaurant_menu_outlined,
                  message: 'メニューがまだ登録されていません',
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (final category in _categoryOrder) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        category.label,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _CategorySection(
                      menus: menus
                          .where((menu) => menu.category == category)
                          .toList(),
                      emptyMessage: '${category.label} のメニューはまだありません',
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.menus, required this.emptyMessage});

  final List<MenuItem> menus;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (menus.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _EmptyState(
          icon: Icons.search_off_outlined,
          message: emptyMessage,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) => _MenuCard(menu: menus[index]),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.menu});

  final MenuItem menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subTextColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _MenuImage(imageUrl: menu.imageUrl),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${menu.price}円',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  const _MenuImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
        size: 36,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder;
    }

    return CocoshibaNetworkImage(
      url: imageUrl!,
      fit: BoxFit.cover,
      placeholder: placeholder,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          color: colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Text(
                      'メニューの取得に失敗しました',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再読み込み'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
