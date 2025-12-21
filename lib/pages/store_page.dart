import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/widgets/store_info_card.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Center(
          child: Text(
            'アクセス',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _StoreAccessSection(),
        const SizedBox(height: 32),
        Center(
          child: Text(
            '店舗情報',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _StoreInfoSection(),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _StoreAccessSection extends StatelessWidget {
  const _StoreAccessSection();

  static const _accessImageAssetPath = 'assets/images/IMG_2363.jpeg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.7);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    Future<void> open(Uri uri) async {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;

        final image = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isCompact ? double.infinity : 520,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                _accessImageAssetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            image,
            const SizedBox(height: 16),
            Text(
              'ココシバに行くには',
              style: titleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '蕨駅からココシバまでの道順と距離。',
              style: textStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '①JR京浜東北線蕨駅下車、蕨駅東口階段下りて東武ストアの前を直進。\n'
                  '②交差点をマクドナルド方面に直進。\n'
                  '③サーティーワンの角を左折。\n'
                  '④まっすぐ行くと芝銀座入口が見えます。\n'
                  '⑤交差点を渡って、芝銀座に入り約80ｍでココシバです。',
                  style: textStyle,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '駅から348m、約6分の距離です。',
              style: textStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Antenna Books & Cafe\n'
              'ココシバ\n'
              '〒333-0866 埼玉県川口市芝5-5-13\n'
              '芝銀座の中です。',
              style: textStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => open(storeMapsUri),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Googleマップで開く'),
            ),
          ],
        );
      },
    );
  }
}

class _StoreInfoSection extends StatelessWidget {
  const _StoreInfoSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.8);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    Future<void> open(Uri uri) async {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          storeDisplayName,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text('住所：$storeAddress', style: textStyle, textAlign: TextAlign.center),
        Text(
          '営業時間：$storeBusinessHours',
          style: textStyle,
          textAlign: TextAlign.center,
        ),
        Text('TEL：$storePhoneNumber', style: textStyle, textAlign: TextAlign.center),
        Text(
          'MAIL：$storeEmailAddress',
          style: textStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => open(storeMapsUri),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Googleマップ'),
            ),
            OutlinedButton.icon(
              onPressed: () => open(storeTelUri),
              icon: const Icon(Icons.call_outlined),
              label: const Text('電話する'),
            ),
            OutlinedButton.icon(
              onPressed: () => open(storeMailUri),
              icon: const Icon(Icons.mail_outline),
              label: const Text('メール'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => open(storeInstagramUri),
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Instagram',
            ),
            IconButton(
              onPressed: () => open(storeFacebookUri),
              icon: const Icon(Icons.facebook_outlined),
              tooltip: 'Facebook',
            ),
            IconButton(
              onPressed: () => open(storeXUri),
              icon: const Icon(Icons.alternate_email),
              tooltip: 'X',
            ),
          ],
        ),
      ],
    );
  }
}
