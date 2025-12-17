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
        const SizedBox(height: 8),
        Text(
          'Cocoshiba Web',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'ブラウザからログインして、会員向け機能にアクセスできます。',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
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
