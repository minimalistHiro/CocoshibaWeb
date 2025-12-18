import 'package:cocoshibaweb/models/menu_item.dart';
import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/menu_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  final MenuService _menuService = MenuService();

  Future<void> _confirmDelete(MenuItem menu) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('確認'),
            content: Text('${menu.name} を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('削除する', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !shouldDelete) return;

    try {
      await _menuService.deleteMenu(menu.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${menu.name} を削除しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メニューの削除に失敗しました')),
      );
    }
  }

  Widget _buildMenuCard(MenuItem menu) {
    return Card(
      child: ListTile(
        onTap: () => context.push('${CocoshibaPaths.adminMenu}/edit/${menu.id}'),
        leading: _MenuThumbnail(imageUrl: menu.imageUrl),
        title: Text(menu.name),
        subtitle: Text('${menu.category.label} ・ ${menu.price}円'),
        trailing: PopupMenuButton<_MenuAction>(
          onSelected: (action) {
            switch (action) {
              case _MenuAction.edit:
                context.push('${CocoshibaPaths.adminMenu}/edit/${menu.id}');
                break;
              case _MenuAction.delete:
                _confirmDelete(menu);
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _MenuAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('編集'),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('削除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminPageHeader(
          title: 'メニュー編集',
          trailing: [
            IconButton(
              tooltip: 'メニューを追加',
              onPressed: () => context.push('${CocoshibaPaths.adminMenu}/new'),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: _menuService.watchMenus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('読み込みに失敗しました。再試行'),
                  ),
                );
              }

              final menus = snapshot.data ?? const <MenuItem>[];
              if (menus.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu_outlined,
                          size: 64, color: Colors.grey.shade500),
                      const SizedBox(height: 16),
                      const Text('登録されたメニューがありません'),
                      const SizedBox(height: 8),
                      const Text('右上の＋ボタンからメニューを追加できます'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemBuilder: (context, index) => _buildMenuCard(menus[index]),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: menus.length,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuThumbnail extends StatelessWidget {
  const _MenuThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: AspectRatio(
          aspectRatio: 1,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey.shade500,
                  ),
                )
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

enum _MenuAction { edit, delete }
