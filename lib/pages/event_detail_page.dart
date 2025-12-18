import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText =
        '${event.startDateTime.year}年${event.startDateTime.month}月${event.startDateTime.day}日';
    final timeText = event.isClosedDay
        ? '終日'
        : '${_hhmm(event.startDateTime)}〜${_hhmm(event.endDateTime)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント詳細'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: event.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$dateText（${_weekdayLabel(event.startDateTime.weekday)}）',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                timeText,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (event.organizer.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '主催: ${event.organizer}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (event.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      event.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Icon(Icons.event,
                            color: Colors.grey.shade500, size: 48),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ],
              if (event.content.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  event.content,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 16),
              if (event.capacity > 0)
                Text(
                  '定員: ${event.capacity}名',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _hhmm(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    return labels[(weekday + 6) % 7];
  }
}
