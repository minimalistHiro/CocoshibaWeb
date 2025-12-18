import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/pages/calendar_page.dart';
import 'package:cocoshibaweb/pages/event_detail_page.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/widgets/event_card.dart';
import 'package:cocoshibaweb/widgets/store_info_card.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static EventService? _eventService;

  static EventService get eventService => _eventService ??= EventService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseReady = Firebase.apps.isNotEmpty;

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
        if (!firebaseReady) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Firebase が初期化されていないため、イベント情報は表示できません。',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CalendarView(embedded: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ReservedEventsSection(),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _UpcomingEventsSection(),
          ),
          const SizedBox(height: 24),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: StoreInfoCard(showActions: false),
        ),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              height: height,
              child: Image.asset(
                'assets/images/books_hero.jpeg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  Text(
                    '人をつなぐ街のブックカフェ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Antenna Books & Cafe',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'ココシバ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'アーティスト、物作り、ノウハウなど、個々人が持っている能力をより活かせる場所、それがAntenna Books & Cafe ココシバです。\n'
                    '個々の「やってみよう」という気持ちを後押しをして、そこで何か表現して人同士の関係が生まれる、そんなカフェを目指しています。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '直近のイベント',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<CalendarEvent>>(
          stream: HomePage.eventService.watchUpcomingEvents(limit: 7),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'イベント情報の取得に失敗しました。\n${snapshot.error}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              );
            }

            final events = snapshot.data ?? const <CalendarEvent>[];
            final visibleEvents =
                events.where((event) => !event.isClosedDay).toList();
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            if (isLoading && visibleEvents.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const CircularProgressIndicator(),
              );
            }

            if (visibleEvents.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '直近のイベントはまだありません',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }

            return _UpcomingEventsScroller(
              events: visibleEvents,
              onEventTap: (event) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => EventDetailPage(event: event)),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ReservedEventsSection extends StatelessWidget {
  const _ReservedEventsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AppServices.of(context).auth;

    return StreamBuilder(
      stream: auth.onAuthStateChanged,
      builder: (context, snapshot) {
        final user = snapshot.data ?? auth.currentUser;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '予約したイベント',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<CalendarEvent>>(
              stream: user == null
                  ? Stream.value(const <CalendarEvent>[])
                  : HomePage.eventService.watchReservedEvents(user.uid),
              builder: (context, reservedSnapshot) {
                final reservedEvents =
                    (reservedSnapshot.data ?? const <CalendarEvent>[])
                        .take(7)
                        .toList(growable: false);

                if (reservedSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    reservedEvents.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (reservedEvents.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '予約したイベントはまだありません',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                return _UpcomingEventsScroller(
                  events: reservedEvents,
                  onEventTap: (event) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: event),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _UpcomingEventsScroller extends StatelessWidget {
  const _UpcomingEventsScroller({
    required this.events,
    required this.onEventTap,
  });

  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double crossAxisSpacing = 16;
        final availableWidth = constraints.maxWidth.clamp(0.0, double.infinity);
        final cardWidth =
            (availableWidth * 0.48).clamp(220.0, 320.0).toDouble();
        final imageHeight = cardWidth;
        final imageCacheWidth = (cardWidth * dpr).round();
        final imageCacheHeight = (imageHeight * dpr).round();
        final totalHeight = imageHeight + 84;

        return SizedBox(
          height: totalHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: events.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: crossAxisSpacing),
            itemBuilder: (context, index) {
              final event = events[index];
              return SizedBox(
                width: cardWidth,
                child: RepaintBoundary(
                  child: EventCard(
                    event: event,
                    onTap: event.isClosedDay ? null : () => onEventTap(event),
                    imageCacheWidth:
                        imageCacheWidth > 0 ? imageCacheWidth : null,
                    imageCacheHeight:
                        imageCacheHeight > 0 ? imageCacheHeight : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
