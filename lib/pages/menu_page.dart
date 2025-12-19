import 'package:cocoshibaweb/models/menu_item.dart';
import 'package:cocoshibaweb/services/menu_service.dart';
import 'package:cocoshibaweb/widgets/cocoshiba_network_image.dart';
import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  late Stream<List<MenuItem>> _menusStream;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _menusStream = _menuService.watchMenus();
    _tabController =
        TabController(length: MenuCategory.values.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  List<MenuItem> _filteredMenus(List<MenuItem> menus) {
    final selected = MenuCategory.values[_tabController.index];
    return menus.where((menu) => menu.category == selected).toList();
  }

  void _reloadMenus() {
    setState(() {
      _menusStream = _menuService.watchMenus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subTextColor = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('メニュー',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const SizedBox(height: 4),
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: subTextColor,
          indicatorColor: theme.colorScheme.primary,
          tabs: MenuCategory.values
              .map((category) => Tab(text: category.label))
              .toList(),
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

              final filtered = _filteredMenus(menus);
              if (filtered.isEmpty) {
                final selected = MenuCategory.values[_tabController.index];
                return _EmptyState(
                  icon: Icons.search_off_outlined,
                  message: '${selected.label} のメニューはまだありません',
                );
              }

              return _MenuGrid(menus: filtered);
            },
          ),
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.menus});

  final List<MenuItem> menus;

  int _crossAxisCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _crossAxisCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: menus.length,
          itemBuilder: (context, index) => _MenuCard(menu: menus[index]),
        );
      },
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: _MenuImage(imageUrl: menu.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 6),
                Text(
                  menu.category.label,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: subTextColor),
                ),
                const SizedBox(height: 4),
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
