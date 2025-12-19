import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/services/owner_service.dart';
import 'package:cocoshibaweb/services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.event});

  final CalendarEvent event;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventService _eventService = EventService();
  final UserProfileService _profileService = UserProfileService();
  late final CalendarEvent _event;
  late final Stream<int> _reservationCountStream;

  bool _hasReservation = false;
  bool _isReservationLoading = true;
  bool _isReservationProcessing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _reservationCountStream =
        _eventService.watchEventReservationCount(_event.id);
    _loadReservationStatus();
  }

  Future<void> _loadReservationStatus() async {
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
      await _eventService.deleteEvent(_event.id);
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

    return StreamBuilder<int>(
      stream: _reservationCountStream,
      builder: (context, snapshot) {
        final reservationCount = snapshot.data ?? 0;
        final isEventEnded = DateTime.now().isAfter(event.endDateTime);
        final isEventFull = _isEventFull(reservationCount);
        final isReservationBusy =
            _isReservationLoading || _isReservationProcessing || _isDeleting;
        final isReservationButtonDisabled = event.isClosedDay ||
            isEventEnded ||
            (!_hasReservation && isEventFull);

        final reservationButtonLabel = event.isClosedDay
            ? '定休日です'
            : isEventEnded
                ? 'イベントは終了しました'
                : _hasReservation
                    ? '予約を解除する'
                    : isEventFull
                        ? '定員に達しました'
                        : '予約する';

        final dateText =
            '${event.startDateTime.year}年${event.startDateTime.month}月${event.startDateTime.day}日（${_weekdayLabel(event.startDateTime.weekday)}）';

        return Scaffold(
          appBar: AppBar(
            title: const Text('イベント詳細'),
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
                        if (event.imageUrls.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              event.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.event,
                                  color: Colors.grey.shade500,
                                  size: 48,
                                ),
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            height: 220,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.event,
                              color: Colors.grey.shade500,
                              size: 48,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(top: 6),
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
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                              _InfoRow(
                                label: '予約人数',
                                value: '$reservationCount人',
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: '日付',
                                value: dateText,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: '時間',
                                value: event.isClosedDay
                                    ? '終日'
                                    : '${_hhmm(event.startDateTime)}〜${_hhmm(event.endDateTime)}',
                              ),
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
                          onPressed:
                              (isReservationButtonDisabled || isReservationBusy)
                                  ? null
                                  : _onReservationButtonPressed,
                          child:
                              isReservationBusy && !isReservationButtonDisabled
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
