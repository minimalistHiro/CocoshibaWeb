import 'package:flutter/material.dart';
import 'package:cocoshibaweb/widgets/store_info_card.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'アクセス',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const _StoreAccessCard(),
        const SizedBox(height: 20),
        Text(
          '店舗情報',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const StoreInfoCard(),
      ],
    );
  }
}

class _StoreAccessCard extends StatelessWidget {
  const _StoreAccessCard();

  static const _accessImageAssetPath = 'assets/images/IMG_2363.jpeg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;

            final image = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: isCompact ? double.infinity : 220,
                height: isCompact ? 180 : 220,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Image.asset(_accessImageAssetPath),
                ),
              ),
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ココシバに行くには',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '蕨駅からココシバまでの道順と距離。',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  '①JR京浜東北線蕨駅下車、蕨駅東口階段下りて東武ストアの前を直進。\n'
                  '②交差点をマクドナルド方面に直進。\n'
                  '③サーティーワンの角を左折。\n'
                  '④まっすぐ行くと芝銀座入口が見えます。\n'
                  '⑤交差点を渡って、芝銀座に入り約80ｍでココシバです。\n'
                  '\n'
                  '駅から348m、約6分の距離です。',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Antenna Books & Cafe\n'
                  'ココシバ\n'
                  '〒333-0866 埼玉県川口市芝5-5-13\n'
                  '芝銀座の中です。',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  image,
                  const SizedBox(height: 12),
                  content,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(width: 16),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}
