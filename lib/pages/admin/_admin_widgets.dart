import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (Navigator.of(context).canPop())
          IconButton(
            tooltip: '戻る',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          )
        else
          const SizedBox(width: 48),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...?trailing,
      ],
    );
  }
}

class FirebaseNotReadyCard extends StatelessWidget {
  const FirebaseNotReadyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Firebase が初期化されていないため、この画面は利用できません。'),
      ),
    );
  }
}

