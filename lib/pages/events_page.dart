import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/pages/event_detail_page.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/widgets/event_card.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  EventService? _eventService;
  late Stream<List<CalendarEvent>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _createEventsStream();
  }

  Stream<List<CalendarEvent>> _createEventsStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const <CalendarEvent>[]);
    }
    _eventService ??= EventService();
    return _eventService!.watchAllExistingEvents(descending: true);
  }

  void _reload() {
    setState(() {
      _eventsStream = _createEventsStream();
    });
  }

  int _crossAxisCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }

  void _openDetail(CalendarEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event, isExistingEvent: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseReady = Firebase.apps.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'イベント',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (!firebaseReady)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Firebase が初期化されていないため、イベント情報は表示できません。',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          Expanded(
            child: StreamBuilder<List<CalendarEvent>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    title: 'イベントの取得に失敗しました',
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  );
                }

                final events = snapshot.data ?? const <CalendarEvent>[];
                final visibleEvents =
                    events.where((event) => !event.isClosedDay).toList();

                if (visibleEvents.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.event_available_outlined,
                    message: '既存イベントがまだありません',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final count = _crossAxisCount(constraints.maxWidth);
                    final dpr = MediaQuery.of(context).devicePixelRatio;
                    final spacing = count > 1 ? 16.0 : 12.0;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (count - 1)) / count;
                    final imageCacheWidth = (cardWidth * dpr).round();
                    final imageCacheHeight = (cardWidth * dpr).round();

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: visibleEvents.length,
                      itemBuilder: (context, index) {
                        final event = visibleEvents[index];
                        return RepaintBoundary(
                          child: EventCard(
                            event: event,
                            onTap: event.isClosedDay
                                ? null
                                : () => _openDetail(event),
                            imageCacheWidth:
                                imageCacheWidth > 0 ? imageCacheWidth : null,
                            imageCacheHeight:
                                imageCacheHeight > 0 ? imageCacheHeight : null,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          color: colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再読み込み'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
