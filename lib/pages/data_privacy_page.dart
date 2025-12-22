import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DataPrivacyPage extends StatelessWidget {
  const DataPrivacyPage({super.key});

  void _showPendingSnack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label は現在準備中です。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sectionTitle(String title) {
      return Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return ListView(
      children: [
        Text(
          'データとプライバシー',
          style:
              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          '登録データの確認やエクスポート、削除に関する情報をまとめています。',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        sectionTitle('保存されるデータ'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('プロフィール情報'),
                subtitle: Text('名前、アイコン、自己紹介など'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.event_available_outlined),
                title: Text('イベント参加・予約履歴'),
                subtitle: Text('参加済みイベント、予約状況'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.shopping_bag_outlined),
                title: Text('注文・問い合わせ履歴'),
                subtitle: Text('本の注文やお問い合わせ内容'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        sectionTitle('データの管理'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('データのエクスポート'),
                subtitle: const Text('登録情報をダウンロード'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPendingSnack(context, 'データのエクスポート'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('データの削除申請'),
                subtitle: const Text('サポート経由で削除申請'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(CocoshibaPaths.supportHelp),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        sectionTitle('プライバシーについて'),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'お預かりしたデータはサービス提供・運営のために利用します。'
              '第三者への提供は行わず、必要に応じて保護・管理を強化します。',
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(CocoshibaPaths.supportHelp),
            icon: const Icon(Icons.help_outline),
            label: const Text('プライバシーについて相談する'),
          ),
        ),
      ],
    );
  }
}
