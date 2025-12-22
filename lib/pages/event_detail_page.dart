import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/pages/event_edit_page.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/services/owner_service.dart';
import 'package:cocoshibaweb/services/user_profile_service.dart';
import 'package:cocoshibaweb/widgets/cocoshiba_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({
    super.key,
    required this.event,
    this.isExistingEvent = false,
    this.title,
    this.showReservationActions = true,
    this.showScheduleInfo = true,
  });

  final CalendarEvent event;
  final bool isExistingEvent;
  final String? title;
  final bool showReservationActions;
  final bool showScheduleInfo;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventService _eventService = EventService();
  final UserProfileService _profileService = UserProfileService();
  late CalendarEvent _event;
  late final Stream<int> _reservationCountStream;
  Stream<List<CalendarEvent>>? _relatedEventsStream;
  late final PageController _imageController;
  int _currentImageIndex = 0;

  bool _hasReservation = false;
  bool _isReservationLoading = true;
  bool _isReservationProcessing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _imageController = PageController();
    final reservationEnabled =
        widget.showReservationActions && !widget.isExistingEvent;
    _reservationCountStream = reservationEnabled
        ? _eventService.watchEventReservationCount(_event.id)
        : Stream.value(0);
    if (widget.isExistingEvent) {
      _relatedEventsStream = _createRelatedEventsStream();
    }
    if (reservationEnabled) {
      _loadReservationStatus();
    } else {
      _isReservationLoading = false;
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadReservationStatus() async {
    if (widget.isExistingEvent) {
      if (mounted) setState(() => _isReservationLoading = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isReservationLoading = false);
      return;
    }

    try {
      final hasReservation = await _eventService.hasReservation(
        eventId: _event.id,
        userId: user.uid,
      );
      if (!mounted) return;
      setState(() {
        _hasReservation = hasReservation;
        _isReservationLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isReservationLoading = false);
    }
  }

  bool _isEventFull(int reservationCount) {
    final capacity = _event.capacity;
    if (capacity <= 0) return false;
    return reservationCount >= capacity;
  }

  Stream<List<CalendarEvent>> _createRelatedEventsStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const <CalendarEvent>[]);
    }
    return _eventService.watchEventsByExistingEventId(_event.id);
  }

  Future<void> _onReservationButtonPressed() async {
    final isCancel = _hasReservation;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isCancel ? '予約解除の確認' : '予約の確認'),
            content: Text(
              isCancel ? 'このイベントの予約を解除しますか？' : 'このイベントを予約しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  isCancel ? '解除する' : '予約する',
                  style: TextStyle(
                    color: isCancel ? Colors.redAccent : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await _toggleReservation();
  }

  Future<void> _toggleReservation() async {
    if (widget.isExistingEvent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このイベントは予約できません')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予約にはログインが必要です')),
      );
      return;
    }

    setState(() => _isReservationProcessing = true);
    try {
      if (_hasReservation) {
        await _eventService.cancelReservation(
          eventId: _event.id,
          userId: user.uid,
        );
        if (!mounted) return;
        setState(() => _hasReservation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予約を解除しました')),
        );
      } else {
        await _eventService.reserveEvent(
          event: _event,
          userId: user.uid,
          userEmail: user.email,
        );
        if (!mounted) return;
        setState(() => _hasReservation = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予約しました')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = _hasReservation ? '予約の解除に失敗しました: $e' : '予約に失敗しました: $e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isReservationProcessing = false);
    }
  }

  Stream<bool> _watchIsOwner() {
    if (Firebase.apps.isEmpty) return Stream.value(false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);
    return _profileService
        .watchProfile(user.uid)
        .map(OwnerService.isOwnerFromProfile)
        .handleError((_) => false);
  }

  Future<void> _onDeletePressed() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('イベント削除の確認'),
            content: const Text('このイベントを削除しますか？\nこの操作は取り消せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('削除する'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _isDeleting = true);
    try {
      if (widget.isExistingEvent) {
        await _eventService.deleteExistingEvent(_event.id);
      } else {
        await _eventService.deleteEvent(_event.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イベントを削除しました')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = _event;
    final reservationEnabled =
        widget.showReservationActions && !widget.isExistingEvent;
    final title =
        widget.title ?? (widget.isExistingEvent ? '既存イベント詳細' : 'イベント詳細');

    return StreamBuilder<int>(
      stream: _reservationCountStream,
      builder: (context, snapshot) {
        final reservationCount = snapshot.data ?? 0;
        final isEventEnded = DateTime.now().isAfter(event.endDateTime);
        final isEventFull = _isEventFull(reservationCount);
        final isReservationBusy =
            _isReservationLoading || _isReservationProcessing || _isDeleting;
        final isReservationButtonDisabled = event.isClosedDay ||
            widget.isExistingEvent ||
            isEventEnded ||
            (!_hasReservation && isEventFull);

        final reservationButtonLabel = event.isClosedDay
            ? '定休日です'
            : widget.isExistingEvent
                ? '予約できません'
                : isEventEnded
                    ? 'イベントは終了しました'
                    : _hasReservation
                        ? '予約を解除する'
                        : isEventFull
                            ? '定員に達しました'
                            : '予約する';

        final dateText = widget.showScheduleInfo
            ? '${event.startDateTime.year}年${event.startDateTime.month}月${event.startDateTime.day}日（${_weekdayLabel(event.startDateTime.weekday)}）'
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              StreamBuilder<bool>(
                stream: _watchIsOwner(),
                builder: (context, ownerSnapshot) {
                  final isOwner = ownerSnapshot.data == true;
                  if (!isOwner) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: '編集',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final updated = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventEditPage(
                            event: _event,
                            isExistingEvent: widget.isExistingEvent,
                          ),
                        ),
                      );
                      if (!mounted || updated is! CalendarEvent) return;
                      setState(() => _event = updated);
                    },
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EventImageCarousel(
                          imageUrls: event.imageUrls,
                          controller: _imageController,
                          currentIndex: _currentImageIndex,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                label: '主催',
                                value: event.organizer.trim().isNotEmpty
                                    ? event.organizer
                                    : '未設定',
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: '定員',
                                value: event.capacity > 0
                                    ? '${event.capacity}人'
                                    : '設定なし',
                              ),
                              const SizedBox(height: 8),
                              if (reservationEnabled) ...[
                                _InfoRow(
                                  label: '予約人数',
                                  value: '$reservationCount人',
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (widget.showScheduleInfo) ...[
                                _InfoRow(
                                  label: '日付',
                                  value: dateText!,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  label: '時間',
                                  value: event.isClosedDay
                                      ? '終日'
                                      : '${_hhmm(event.startDateTime)}〜${_hhmm(event.endDateTime)}',
                                ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                'イベント内容',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.content.trim().isNotEmpty
                                    ? event.content
                                    : '記載なし',
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (widget.isExistingEvent) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'イベント一覧',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _ExistingEventsList(
                                  eventsStream: _relatedEventsStream,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<bool>(
                        stream: _watchIsOwner(),
                        builder: (context, ownerSnapshot) {
                          final isOwner = ownerSnapshot.data == true;
                          if (!isOwner) return const SizedBox.shrink();
                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: const StadiumBorder(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _isDeleting ? null : _onDeletePressed,
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('イベントを削除する'),
                            ),
                          );
                        },
                      ),
                      if (reservationEnabled) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _hasReservation
                                  ? Colors.redAccent
                                  : Theme.of(context).colorScheme.primary,
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: (isReservationButtonDisabled ||
                                    isReservationBusy)
                                ? null
                                : _onReservationButtonPressed,
                            child: isReservationBusy &&
                                    !isReservationButtonDisabled
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(reservationButtonLabel),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

class _EventImageCarousel extends StatelessWidget {
  const _EventImageCarousel({
    required this.imageUrls,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> imageUrls;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.event,
        color: Colors.grey.shade500,
        size: 48,
      ),
    );

    if (imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: placeholder,
      );
    }

    final safeIndex = currentIndex.clamp(0, imageUrls.length - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: controller,
            itemCount: imageUrls.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return CocoshibaNetworkImage(
                url: imageUrls[index],
                fit: BoxFit.cover,
                placeholder: placeholder,
              );
            },
          ),
        ),
        if (imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == safeIndex
                        ? Colors.black87
                        : Colors.black26,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExistingEventsList extends StatelessWidget {
  const _ExistingEventsList({
    required this.eventsStream,
  });

  final Stream<List<CalendarEvent>>? eventsStream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stream = eventsStream;
    if (stream == null) {
      return const _InlineMessage(message: 'イベント情報を取得できません。');
    }

    return StreamBuilder<List<CalendarEvent>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const _InlineMessage(message: '既存イベントの取得に失敗しました。');
        }

        final events = snapshot.data ?? const <CalendarEvent>[];
        final now = DateTime.now();
        final visibleEvents = events
            .where((event) => !event.endDateTime.isBefore(now))
            .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        if (visibleEvents.isEmpty) {
          return const _InlineMessage(message: '開催予定のイベントはありません');
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleEvents.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final event = visibleEvents[index];
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventDetailPage(event: event),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              _formatEventDate(event.startDateTime),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatEventTime(event),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child:
                            Icon(Icons.chevron_right, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatEventDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日（${_weekdayLabel(date.weekday)}）';
  }

  String _formatEventTime(CalendarEvent event) {
    if (event.isClosedDay) return '終日';
    return '${_hhmm(event.startDateTime)}〜${_hhmm(event.endDateTime)}';
  }

  String _hhmm(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    return labels[(weekday + 6) % 7];
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: Colors.grey.shade700),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
