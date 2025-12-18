import 'package:cocoshibaweb/pages/calendar_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        const _HeroSection(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/IMG_3803.jpeg'),
              ),
              const SizedBox(height: 16),
              Text(
                'ココシバは、数々のイベントを開催しております。ボードゲーム会、ハンドメイド・スローマーケット、クッキング&パーティ、スナック木曜日、アーティストLIVE、読書会などなど。以下のカレンダーより、予約することができます。',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: const CalendarView(embedded: true),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Image.asset('assets/images/IMG_1385.jpeg'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antenna Books & Cafe ココシバ\n'
                          '電話番号：080-6050-7194\n'
                          'メールアドレス：h.kaneko.baseball@icloud.com',
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _openGoogleMaps,
                          child: Text(
                            '住所：埼玉県川口市芝5-5-13（Googleマップで開く）',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '営業時間：11:00〜18:00（月、火定休）',
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final Uri _mapsUri = Uri.parse(
  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('Antenna Books & Cafe ココシバ')}',
);

Future<void> _openGoogleMaps() async {
  await launchUrl(_mapsUri, mode: LaunchMode.externalApplication);
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 0.45).clamp(320.0, 520.0);
        return SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/books_hero.jpeg',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '人をつなぐ街のブックカフェ',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Antenna Books & Cafe',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'ココシバ',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'アーティスト、物作り、ノウハウなど、個々人が持っている能力をより活かせる場所、それがAntenna Books & Cafe ココシバです。\n個々の「やってみよう」という気持ちを後押しをして、そこで何か表現して人同士の関係が生まれる、そんなカフェを目指しています。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
