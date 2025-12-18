import 'package:flutter/material.dart';
import 'package:cocoshibaweb/widgets/store_info_card.dart';
import 'package:url_launcher/url_launcher.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          '店舗情報',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const StoreInfoCard(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'アクセス',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '最寄り駅などの詳細は、Googleマップをご確認ください。',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async => launchUrl(
                      storeMapsUri,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Googleマップを開く'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
