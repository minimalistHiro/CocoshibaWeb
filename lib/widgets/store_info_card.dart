import 'package:cocoshibaweb/app.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const storePhoneNumber = '080-6050-7194';
const storeEmailAddress = 'h.kaneko.baseball@icloud.com';
const storeAddress = '埼玉県川口市芝5-5-13';
const storeBusinessHours = '11:00〜18:00（月、火定休）';

final Uri storeMapsUri = Uri.parse(
  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(storeDisplayName)}',
);

final Uri storeTelUri = Uri(scheme: 'tel', path: storePhoneNumber);
final Uri storeMailUri = Uri(scheme: 'mailto', path: storeEmailAddress);

class StoreInfoCard extends StatelessWidget {
  const StoreInfoCard({
    super.key,
    this.showActions = true,
    this.imageAssetPath = 'assets/images/IMG_1385.jpeg',
  });

  final bool showActions;
  final String imageAssetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    Future<void> open(Uri uri) async {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    Widget addressLink() {
      return InkWell(
        onTap: () => open(storeMapsUri),
        child: Text(
          '住所：$storeAddress（Googleマップで開く）',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    Widget info() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storeDisplayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LinkChip(
                icon: Icons.call_outlined,
                label: storePhoneNumber,
                onTap: () => open(storeTelUri),
              ),
              _LinkChip(
                icon: Icons.mail_outline,
                label: storeEmailAddress,
                onTap: () => open(storeMailUri),
              ),
            ],
          ),
          const SizedBox(height: 12),
          addressLink(),
          const SizedBox(height: 8),
          Text(
            '営業時間：$storeBusinessHours',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          if (showActions) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
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
          ],
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;

            final image = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: isCompact ? double.infinity : 110,
                height: isCompact ? 180 : 110,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Image.asset(imageAssetPath),
                ),
              ),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  image,
                  const SizedBox(height: 12),
                  info(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(width: 12),
                Expanded(child: info()),
                const SizedBox(width: 8),
                Icon(Icons.storefront_outlined, color: onSurfaceVariant),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

