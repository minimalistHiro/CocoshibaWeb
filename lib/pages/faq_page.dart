import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'よくある質問',
          style:
              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'アカウント、イベント参加などの質問をまとめています。',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const _FaqTile(
          question: 'ログインできません',
          answer:
              'メールアドレスとパスワードをご確認ください。パスワードを忘れた場合はログイン画面の「パスワードリセット」から再設定できます。',
        ),
        const _FaqTile(
          question: 'プロフィール画像が表示されません',
          answer:
              'プロフィール編集で設定した画像URLが正しいか、ブラウザで直接開けるかをご確認ください（https:// から始まるURL推奨）。',
        ),
        const _FaqTile(
          question: 'イベントの予約ができません',
          answer:
              'ログイン状態を確認し、対象イベントが満席または締切になっていないかご確認ください。解決しない場合は「サポート・ヘルプ」からお問い合わせください。',
        ),
        const _FaqTile(
          question: '退会したい',
          answer: '現在、Web版では退会フローは準備中です。サポートへご連絡ください。',
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(answer)],
      ),
    );
  }
}
