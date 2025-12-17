import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  static final Uri _googleMaps = Uri.parse('https://maps.google.com/');
  static final Uri _instagram = Uri.parse('https://www.instagram.com/');
  static final Uri _x = Uri.parse('https://x.com/');

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          '店舗情報',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('営業時間（仮）', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('平日 11:00-15:00 / 17:00-20:00'),
                const Text('土日祝 11:00-20:00'),
                const SizedBox(height: 16),
                const Text('住所（仮）', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('〒000-0000 東京都〇〇区〇〇 1-2-3'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _open(_googleMaps),
                      icon: const Icon(Icons.map),
                      label: const Text('Google Maps'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _open(_instagram),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Instagram'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _open(_x),
                      icon: const Icon(Icons.alternate_email),
                      label: const Text('X'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

