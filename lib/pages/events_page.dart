import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/widgets/event_card.dart';
import 'package:cocoshibaweb/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cocoshibaweb/router.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  EventService? _eventService;
  late Stream<List<CalendarEvent>> _eventsStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _eventsStream = _createEventsStream();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<CalendarEvent>> _createEventsStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const <CalendarEvent>[]);
    }
    _eventService ??= EventService();
    return _eventService!.watchAllExistingEvents(descending: false);
  }

  void _reload() {
    setState(() {
      _eventsStream = _createEventsStream();
    });
  }

  int _crossAxisCount(double width) {
    return width < 520 ? 1 : 2;
  }

  double _childAspectRatio(double width) {
    return width < 520 ? 2.0 : 1.0;
  }

  void _openDetail(CalendarEvent event) {
    context.push(CocoshibaPaths.existingEventDetail, extra: event);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const textColor = Colors.black;
    final firebaseReady = Firebase.apps.isNotEmpty;
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset(
                      'assets/images/IMG_5959.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'イベント',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ココシバでは、多彩なイベントを開催しています。\n予約が必要なもの、不要なものがございますので、是非お気軽にご参加下さい。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go(CocoshibaPaths.calendar),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cocoshibaMainColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('イベントスケジュールはこちら'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          if (!firebaseReady)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Firebase が初期化されていないため、イベント情報は表示できません。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                ),
              ),
            )
          else
            StreamBuilder<List<CalendarEvent>>(
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
                    final verticalSpacing = count > 1 ? 40.0 : 30.0;
                    final cardWidth = (constraints.maxWidth -
                            spacing * (count - 1)) /
                        count;
                    final childAspectRatio =
                        _childAspectRatio(constraints.maxWidth);
                    final cardHeight = cardWidth / childAspectRatio;
                    final imageCacheWidth = (cardWidth * dpr).round();
                    final imageCacheHeight = (cardHeight * dpr).round();

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: verticalSpacing,
                        childAspectRatio: childAspectRatio,
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
                            imageAspectRatio: childAspectRatio,
                            imageCacheWidth:
                                imageCacheWidth > 0 ? imageCacheWidth : null,
                            imageCacheHeight: imageCacheHeight > 0
                                ? imageCacheHeight
                                : null,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
        ],
      ),
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
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black),
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
    const textColor = Colors.black;

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
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再読み込み'),
                  style:
                      FilledButton.styleFrom(foregroundColor: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
