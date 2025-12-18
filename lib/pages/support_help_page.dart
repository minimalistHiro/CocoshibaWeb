import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportHelpPage extends StatelessWidget {
  const SupportHelpPage({super.key});

  static const String _supportEmail = 'h.kaneko.baseball@icloud.com';
  static const String _supportPhone = '080-6050-7194';
  static const String _businessHours = '11:00〜18:00（月、火定休）';
  static final Uri _mapsUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('Antenna Books & Cafe ココシバ')}',
  );

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${uri.scheme} を開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'サポート・ヘルプ',
          style:
              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          '困ったときの連絡先やガイドをご案内します。',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('メールで問い合わせ'),
            subtitle: const Text(_supportEmail),
            trailing: const Icon(Icons.send),
            onTap: () => _launchUri(
              context,
              Uri(scheme: 'mailto', path: _supportEmail),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('電話で問い合わせ'),
            subtitle: const Text('$_supportPhone / $_businessHours'),
            trailing: const Icon(Icons.call),
            onTap: () => _launchUri(
              context,
              Uri(scheme: 'tel', path: _supportPhone.replaceAll('-', '')),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Googleマップで開く'),
            subtitle: const Text('店舗の場所を確認'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUri(context, _mapsUri),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.help_center_outlined),
            title: const Text('よくある質問'),
            subtitle: const Text('アカウント、イベント参加など'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/_/faq'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '最近のアナウンス',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            title: Text('Web版を公開しました'),
            subtitle: Text('プロフィール編集とイベント閲覧が利用できます'),
          ),
        ),
        const Card(
          child: ListTile(
            title: Text('フィードバック募集中'),
            subtitle: Text('改善要望や不具合報告をお待ちしています'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _launchUri(
              context,
              Uri(
                scheme: 'mailto',
                path: _supportEmail,
                queryParameters: const {'subject': 'CocoshibaWeb フィードバック'},
              ),
            ),
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('フィードバックを送信'),
          ),
        ),
      ],
    );
  }
}
