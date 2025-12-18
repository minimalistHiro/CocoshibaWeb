import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;

    return ListView(
      children: [
        const _HeroSection(),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder(
              stream: auth.onAuthStateChanged,
              builder: (context, snapshot) {
                final user = snapshot.data ?? auth.currentUser;
                if (user == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'まずはログイン',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text('メールアドレスとパスワードでログインできます。'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            onPressed: () => context.go(CocoshibaPaths.login),
                            child: const Text('ログイン'),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go(CocoshibaPaths.signup),
                            child: const Text('アカウント作成'),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ログイン中',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text('メール: ${user.email ?? "(未設定)"}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go(CocoshibaPaths.account),
                      child: const Text('アカウント管理へ'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _QuickLinks(),
      ],
    );
  }
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

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _LinkCard(
          title: 'カレンダー',
          description: '営業日・イベント情報（仮）',
          to: CocoshibaPaths.calendar,
        ),
        _LinkCard(
          title: 'メニュー',
          description: '定番メニュー（仮）',
          to: CocoshibaPaths.menu,
        ),
        _LinkCard(
          title: '店舗情報',
          description: '営業時間・アクセス',
          to: CocoshibaPaths.store,
        ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.title,
    required this.description,
    required this.to,
  });

  final String title;
  final String description;
  final String to;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: InkWell(
        onTap: () => context.go(to),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(description),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
