import 'dart:math' as math;

import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/services/owner_service.dart';
import 'package:cocoshibaweb/utils/print_helper.dart';
import 'package:cocoshibaweb/widgets/cocoshiba_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalendarView();
  }
}

class CalendarView extends StatefulWidget {
  const CalendarView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  EventService? _eventService;

  static final DateTime _fixedStartDate = DateTime(2025, 12, 1);
  static final DateTime _fixedEndDate = DateTime(2026, 12, 31);

  late final DateTime _startDate;
  late final DateTime _endDate;
  late final int _monthCount;
  late final PageController _pageController;
  late final Stream<List<CalendarEvent>> _eventsStream;

  late int _currentPage;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = _fixedStartDate;
    _endDate = _fixedEndDate;

    _monthCount = (_endDate.year - _startDate.year) * 12 +
        (_endDate.month - _startDate.month) +
        1;

    _currentPage = _initialPageFor(now);
    _pageController = PageController(initialPage: _currentPage);
    _selectedDate = _clampDate(now);

    if (Firebase.apps.isEmpty) {
      _eventsStream = Stream.value(const <CalendarEvent>[]);
    } else {
      _eventService = EventService();
      _eventsStream =
          _eventService!.watchEvents(startDate: _startDate, endDate: _endDate);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _clampDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(_startDate)) return _startDate;
    if (day.isAfter(_endDate)) return _endDate;
    return day;
  }

  int _initialPageFor(DateTime target) {
    if (target.isBefore(_startDate)) return 0;
    if (target.isAfter(_endDate)) return _monthCount - 1;
    return (target.year - _startDate.year) * 12 +
        (target.month - _startDate.month);
  }

  DateTime _monthForIndex(int index) {
    return DateTime(_startDate.year, _startDate.month + index, 1);
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _monthCount) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMonth = _monthForIndex(_currentPage);
    final screenHeight = MediaQuery.of(context).size.height;
    final calendarHeight = math.max(screenHeight * 0.55, 520.0);

    return StreamBuilder<List<CalendarEvent>>(
      stream: _eventsStream,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <CalendarEvent>[];
    final grouped = _groupEvents(events);
    final selectedEvents = _eventsForDate(grouped, _selectedDate);
    final printMonths = _buildPrintMonths(events, currentMonth);

    final content = _CalendarContent(
      calendarHeight: calendarHeight,
      header: _buildHeader(
        context,
            theme,
            currentMonth,
            selectedDate: _selectedDate,
            showCreateButton: !widget.embedded,
          ),
          snapshot: snapshot,
          groupedEvents: grouped,
          selectedEvents: selectedEvents,
          selectedDate: _selectedDate,
          onSelectDate: (date) => setState(() => _selectedDate = date),
          onTapEvent: (event) => _openEventDetail(context, event),
          weekdayLabel: _weekdayLabel,
          monthCount: _monthCount,
          pageController: _pageController,
          monthForIndex: _monthForIndex,
      eventsForMonth: (month) => _eventsForMonth(grouped, month),
      embedded: widget.embedded,
      onPageChanged: (index) => setState(() => _currentPage = index),
      onPrintSchedule: widget.embedded
          ? null
          : () => printSchedule(printMonths),
    );

        if (widget.embedded) return content;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    DateTime currentMonth, {
    required DateTime? selectedDate,
    required bool showCreateButton,
  }) {
    final hasPrev = _currentPage > 0;
    final hasNext = _currentPage < _monthCount - 1;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 48, height: 48),
            Expanded(
              child: Center(
                child: Text(
                  'イベントスケジュール',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ),
            if (showCreateButton)
              _OwnerCreateEventButton(selectedDate: selectedDate)
            else
              const SizedBox(width: 48, height: 48),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (hasPrev)
              IconButton(
                onPressed: () => _goToPage(_currentPage - 1),
                icon: Icon(Icons.chevron_left, color: subTextColor),
                tooltip: '前の月',
              )
            else
              const SizedBox(width: 48, height: 48),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${currentMonth.year}年${currentMonth.month}月',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '対象期間：${_rangeLabel(_startDate)}〜${_rangeLabel(_endDate)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: subTextColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (hasNext)
              IconButton(
                onPressed: () => _goToPage(_currentPage + 1),
                icon: Icon(Icons.chevron_right, color: subTextColor),
                tooltip: '次の月',
              )
            else
              const SizedBox(width: 48, height: 48),
          ],
        ),
      ],
    );
  }

  String _rangeLabel(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Map<String, List<CalendarEvent>> _groupEvents(List<CalendarEvent> events) {
    final Map<String, List<CalendarEvent>> result = {};
    for (final event in events) {
      final key = _dateKey(event.startDateTime);
      result.putIfAbsent(key, () => []).add(event);
    }
    return result;
  }

  List<CalendarEvent> _eventsForDate(
    Map<String, List<CalendarEvent>> grouped,
    DateTime? date,
  ) {
    if (date == null) return const [];
    return grouped[_dateKey(date)] ?? const [];
  }

  Map<int, List<CalendarEvent>> _eventsForMonth(
    Map<String, List<CalendarEvent>> grouped,
    DateTime month,
  ) {
    final Map<int, List<CalendarEvent>> result = {};
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final events = grouped[_dateKey(date)];
      if (events != null && events.isNotEmpty) {
        result[day] = events;
      }
    }
    return result;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    return labels[(weekday + 6) % 7];
  }

  List<PrintMonthData> _buildPrintMonths(
    List<CalendarEvent> events,
    DateTime currentMonth,
  ) {
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    return [
      _buildPrintMonthData(events, currentMonth),
      _buildPrintMonthData(events, nextMonth),
    ];
  }

  PrintMonthData _buildPrintMonthData(
    List<CalendarEvent> events,
    DateTime month,
  ) {
    final grouped = _groupEvents(events);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final days = List.generate(daysInMonth, (index) {
      final day = index + 1;
      final date = DateTime(month.year, month.month, day);
      final dayEvents = grouped[_dateKey(date)] ?? const <CalendarEvent>[];
      return PrintDayData(
        dayLabel: '$day',
        weekdayLabel: _weekdayLabel(date.weekday),
        events: dayEvents
            .map(
              (event) => PrintEventData(
                title: event.name,
                timeLabel: event.isClosedDay ? '' : _formatTimeRange(event),
              ),
            )
            .toList(growable: false),
        isClosedDay: dayEvents.any((event) => event.isClosedDay),
      );
    });
    return PrintMonthData(
      monthLabel: '${month.month}月',
      days: days,
    );
  }

  void _openEventDetail(BuildContext context, CalendarEvent event) {
    context.push(CocoshibaPaths.calendarEventDetail, extra: event);
  }
}

class _OwnerCreateEventButton extends StatelessWidget {
  const _OwnerCreateEventButton({required this.selectedDate});

  final DateTime? selectedDate;

  String _dateParam(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final user = auth.currentUser;
    final ownerService = OwnerService();

    return StreamBuilder<bool>(
      stream: ownerService.watchIsOwner(user),
      builder: (context, snapshot) {
        final isOwner = snapshot.data == true;
        if (!isOwner) return const SizedBox(width: 48, height: 48);

        final date = selectedDate;
        final suffix = date == null ? '' : '?date=${_dateParam(date)}';

        return IconButton(
          onPressed: () =>
              context.push('${CocoshibaPaths.calendarEventCreate}$suffix'),
          icon: const Icon(Icons.add_circle_outline),
          tooltip: '新規イベント作成',
        );
      },
    );
  }
}

class _CalendarContent extends StatelessWidget {
  const _CalendarContent({
    required this.calendarHeight,
    required this.header,
    required this.snapshot,
    required this.groupedEvents,
    required this.selectedEvents,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onTapEvent,
    required this.weekdayLabel,
    required this.monthCount,
    required this.pageController,
    required this.monthForIndex,
    required this.eventsForMonth,
    required this.embedded,
    required this.onPageChanged,
    this.onPrintSchedule,
  });

  final double calendarHeight;
  final Widget header;
  final AsyncSnapshot<List<CalendarEvent>> snapshot;
  final Map<String, List<CalendarEvent>> groupedEvents;
  final List<CalendarEvent> selectedEvents;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final void Function(CalendarEvent event) onTapEvent;
  final String Function(int weekday) weekdayLabel;
  final int monthCount;
  final PageController pageController;
  final DateTime Function(int index) monthForIndex;
  final Map<int, List<CalendarEvent>> Function(DateTime month) eventsForMonth;
  final bool embedded;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onPrintSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: header,
        ),
        if (snapshot.hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'カレンダー情報の取得に失敗しました。\n${snapshot.error}',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizedBox(
          height: calendarHeight,
          child: PageView.builder(
            controller: pageController,
            itemCount: monthCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final month = monthForIndex(index);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        const _WeekdayHeader(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _MonthGrid(
                            month: month,
                            selectedDate: selectedDate,
                            eventsForMonth: eventsForMonth(month),
                            onSelectDate: onSelectDate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (onPrintSchedule != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: onPrintSchedule,
                icon: const Icon(Icons.print_outlined),
                label: const Text('印刷する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cocoshibaMainColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: _EventList(
            selectedDate: selectedDate,
            events: selectedEvents,
            weekdayLabel: weekdayLabel,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            onTap: onTapEvent,
          ),
        ),
      ],
    );

    if (embedded) return content;

    return content;
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const List<String> _labels = ['日', '月', '火', '水', '木', '金', '土'];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: List.generate(_labels.length, (index) {
        final labelColor = index == 0
            ? Colors.red
            : index == 6
                ? Colors.blue
                : color.withOpacity(0.85);
        return Expanded(
          child: Text(
            _labels[index],
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: labelColor, fontWeight: FontWeight.w700),
          ),
        );
      }),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.onSelectDate,
    required this.eventsForMonth,
  });

  final DateTime month;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final Map<int, List<CalendarEvent>> eventsForMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final leadingEmpty = firstDayOfMonth.weekday % 7;
    final totalCells = ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 11) ??
        const TextStyle(fontSize: 11);

    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisSpacing = 2.0;
        const mainAxisSpacing = 2.0;

        final cellWidth = (constraints.maxWidth - crossAxisSpacing * 6) / 7.0;
        final mainAxisExtent =
            math.min(112.0, math.max(72.0, cellWidth * 0.72));

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - leadingEmpty + 1;
            final isInMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
            final weekdayIndex = index % 7;
            final cellDate =
                isInMonth ? DateTime(month.year, month.month, dayNumber) : null;

            final isToday = cellDate == todayDate;
            final isSelected = isInMonth &&
                selectedDate != null &&
                cellDate != null &&
                cellDate == selectedDate;

            final textColor = weekdayIndex == 0
                ? Colors.red
                : weekdayIndex == 6
                    ? Colors.blue
                    : theme.colorScheme.onSurface.withOpacity(0.85);

            final backgroundColor = !isInMonth
                ? Colors.transparent
                : isToday
                    ? theme.colorScheme.primary.withOpacity(0.08)
                    : theme.colorScheme.surface;

            final events =
                isInMonth ? eventsForMonth[dayNumber] ?? const [] : const [];

            final content = DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
                color: backgroundColor,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isInMonth ? '$dayNumber' : '',
                      style: baseStyle.copyWith(
                        color: isInMonth ? textColor : Colors.transparent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: events.isNotEmpty
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: events
                                    .take(2)
                                    .map(
                                      (event) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                event.color.withOpacity(0.14),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            event.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  event.color.withOpacity(0.95),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (!isInMonth || cellDate == null) return content;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelectDate(cellDate),
              child: content,
            );
          },
        );
      },
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.selectedDate,
    required this.events,
    required this.weekdayLabel,
    required this.isLoading,
    required this.onTap,
  });

  final DateTime? selectedDate;
  final List<CalendarEvent> events;
  final String Function(int weekday) weekdayLabel;
  final bool isLoading;
  final void Function(CalendarEvent event) onTap;

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final label =
        '${selectedDate!.year}年${selectedDate!.month}月${selectedDate!.day}日（${weekdayLabel(selectedDate!.weekday)}）';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading && events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          )
        else if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('この日の予定はありません'),
          )
        else
          Column(
            children: events
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EventCard(event: event, onTap: () => onTap(event)),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = event.isClosedDay ? '定休日' : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRect(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: event.isClosedDay ? null : onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EventThumbnail(
                  imageUrl:
                      event.imageUrls.isNotEmpty ? event.imageUrls.first : null,
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: event.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDate(event.startDateTime)}  ${_formatTimeRange(event)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (event.organizer.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      event.organizer,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!event.isClosedDay)
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                      if (statusLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _StatusChip(
                            label: statusLabel,
                            color: Colors.red.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final y = dateTime.year;
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y/$m/$d';
}

String _formatTimeRange(CalendarEvent event) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final start =
      '${twoDigits(event.startDateTime.hour)}:${twoDigits(event.startDateTime.minute)}';
  final end =
      '${twoDigits(event.endDateTime.hour)}:${twoDigits(event.endDateTime.minute)}';
  return event.isClosedDay ? '終日' : '$start〜$end';
}

class _EventThumbnail extends StatelessWidget {
  const _EventThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.event, color: Colors.grey.shade500, size: 48),
    );

    return AspectRatio(
      aspectRatio: 2 / 1,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? placeholder
          : CocoshibaNetworkImage(
              url: imageUrl!,
              fit: BoxFit.cover,
              placeholder: placeholder,
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
