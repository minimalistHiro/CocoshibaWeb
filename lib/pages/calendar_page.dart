import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          'カレンダー',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const Text('MVP: ここに営業日・イベント情報を表示します（仮）。'),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今週の予定（サンプル）', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('・水曜: 定休日'),
                Text('・土曜: 限定メニュー day'),
                Text('・日曜: 仕込みのため早仕舞い'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
