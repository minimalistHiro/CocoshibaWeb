import 'dart:convert';

import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static const _menuJson = '''
[
  {"name":"醤油らーめん","price":900,"note":"定番"},
  {"name":"塩らーめん","price":900,"note":"さっぱり"},
  {"name":"味玉","price":150,"note":"トッピング"},
  {"name":"チャーシュー増し","price":300,"note":"トッピング"}
]
''';

  @override
  Widget build(BuildContext context) {
    final items = (jsonDecode(_menuJson) as List)
        .cast<Map<String, dynamic>>()
        .map((e) => _MenuItem(
              name: e['name'] as String,
              price: e['price'] as int,
              note: e['note'] as String?,
            ))
        .toList();

    return ListView(
      children: [
        Text(
          'メニュー',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const Text('MVP: 静的JSONから一覧表示しています。'),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.name),
                subtitle: item.note == null ? null : Text(item.note!),
                trailing: Text('¥${item.price}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.name, required this.price, this.note});

  final String name;
  final int price;
  final String? note;
}

