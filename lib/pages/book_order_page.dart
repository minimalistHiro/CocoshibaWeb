import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookOrderPage extends StatelessWidget {
  const BookOrderPage({super.key});

  static final Uri _bookOrderFormUri = Uri.parse(
    'https://docs.google.com/forms/d/e/1FAIpQLSda9VfM-EMborsiY-h11leW1uXgNUPdwv3RFb4_I1GjwFSoOQ/viewform?pli=1',
  );

  static const String _description = '「ココシバは本屋さんててたりとと提携し、新刊書籍・雑誌を注文することができます。\n'
      '\n'
      '入荷し次第、ご連絡させていただきますが、到着までは数日～10日程度。\n'
      'ときには2週間以上かかる場合もございます。ご了承ください。」';

  Future<void> _openOrderForm(BuildContext context) async {
    final ok = await launchUrl(
      _bookOrderFormUri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本の注文ページを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Image.asset(
              'assets/images/books_hero.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '本の注文',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          _description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
        ),
        const SizedBox(height: 28),
        _BookOrderButton(
          onTap: () => _openOrderForm(context),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BookOrderButton extends StatelessWidget {
  const _BookOrderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(32);

    return Material(
      elevation: 4,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      shadowColor: theme.colorScheme.secondary.withOpacity(0.4),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          image: const DecorationImage(
            image: ExactAssetImage('assets/images/books_hero.jpeg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54,
              BlendMode.darken,
            ),
          ),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_stories, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '本の注文はこちら',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
