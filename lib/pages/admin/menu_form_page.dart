import 'package:cocoshibaweb/models/menu_item.dart';
import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/services/menu_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuFormPage extends StatefulWidget {
  const MenuFormPage({super.key, this.menuId});

  final String? menuId;

  @override
  State<MenuFormPage> createState() => _MenuFormPageState();
}

class _MenuFormPageState extends State<MenuFormPage> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  MenuCategory _category = MenuCategory.food;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  bool get _isEdit => widget.menuId != null && widget.menuId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (Firebase.apps.isEmpty) return;
    final id = widget.menuId;
    if (id == null) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final menu = await _menuService.fetchMenu(id);
      if (!mounted) return;
      if (menu == null) {
        setState(() {
          _loadError = 'メニューが見つかりませんでした。';
          _isLoading = false;
        });
        return;
      }
      _nameController.text = menu.name;
      _priceController.text = menu.price.toString();
      _imageUrlController.text = (menu.imageUrl ?? '').trim();
      _category = menu.category;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = '読み込みに失敗しました。';
        _isLoading = false;
      });
    }
  }

  int? _parsePrice(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  Future<void> _save() async {
    if (Firebase.apps.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = _parsePrice(_priceController.text);
    if (price == null) return;

    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await _menuService.updateMenu(
          widget.menuId!,
          name: _nameController.text,
          price: price,
          category: _category,
          imageUrl: _imageUrlController.text,
        );
      } else {
        await _menuService.createMenu(
          name: _nameController.text,
          price: price,
          category: _category,
          imageUrl: _imageUrlController.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'メニューを更新しました' : 'メニューを追加しました')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ListView(
        children: [
          const AdminPageHeader(title: 'メニュー編集'),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_loadError!))),
        ],
      );
    }

    return ListView(
      children: [
        AdminPageHeader(title: _isEdit ? 'メニューを編集' : '新規メニュー作成'),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'メニュー名',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'メニュー名を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<MenuCategory>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'カテゴリ'),
                        items: MenuCategory.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            setState(() => _category = value ?? _category),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '価格（円）',
                        ),
                        validator: (value) {
                          final parsed = _parsePrice(value ?? '');
                          if (parsed == null) return '価格を入力してください';
                          if (parsed < 0) return '0以上で入力してください';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: '画像URL（任意）',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isEdit ? '更新する' : '追加する'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
