import 'dart:math' as math;

import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/services/closed_days_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ClosedDaysSettingsPage extends StatefulWidget {
  const ClosedDaysSettingsPage({super.key});

  @override
  State<ClosedDaysSettingsPage> createState() => _ClosedDaysSettingsPageState();
}

class _ClosedDaysSettingsPageState extends State<ClosedDaysSettingsPage> {
  static final DateTime _startDate = DateTime(2025, 12, 1);
  static final DateTime _endDate = DateTime(2026, 12, 31);

  final ClosedDaysService _service = ClosedDaysService();
  final Set<DateTime> _persisted = <DateTime>{};
  final Set<DateTime> _selected = <DateTime>{};

  late final int _monthCount = (_endDate.year - _startDate.year) * 12 +
      (_endDate.month - _startDate.month) +
      1;
  late final PageController _pageController;
  late int _currentPage;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPageFor(DateTime.now());
    _pageController = PageController(initialPage: _currentPage);
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  int _initialPageFor(DateTime target) {
    if (target.isBefore(_startDate)) return 0;
    if (target.isAfter(_endDate)) return _monthCount - 1;
    return (target.year - _startDate.year) * 12 +
        (target.month - _startDate.month);
  }

  DateTime _monthForIndex(int index) {
    return DateTime(_startDate.year, _startDate.month + index, 1);
  }

  Future<void> _load() async {
    if (Firebase.apps.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final closedDays = await _service.fetchClosedDays(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _persisted
          ..clear()
          ..addAll(closedDays);
        _selected
          ..clear()
          ..addAll(closedDays);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定休日の取得に失敗しました')),
      );
    }
  }

  void _toggle(DateTime date) {
    if (_isSaving) return;
    final normalized = _normalize(date);
    setState(() {
      if (_selected.contains(normalized)) {
        _selected.remove(normalized);
      } else {
        _selected.add(normalized);
      }
    });
  }

  Future<void> _confirmAndSave() async {
    if (_isSaving) return;
    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('確認'),
            content: Text('選択中の${_selected.length}日を定休日として保存しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('保存する'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !shouldSave) return;

    setState(() => _isSaving = true);
    try {
      final toDelete = _persisted.difference(_selected);
      for (final date in toDelete) {
        await _service.deleteClosedDay(date);
      }
      await _service.saveClosedDays(_selected);
      if (!mounted) return;
      setState(() {
        _persisted
          ..clear()
          ..addAll(_selected);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('定休日を${_selected.length}件保存しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定休日の保存に失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    final currentMonth = _monthForIndex(_currentPage);
    final screenHeight = MediaQuery.of(context).size.height;
    final calendarHeight = math.max(screenHeight * 0.55, 520.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminPageHeader(
          title: '定休日設定',
          trailing: [
            FilledButton.icon(
              onPressed: _isLoading || _isSaving ? null : _confirmAndSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('保存'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '休業日にしたい日をカレンダーから複数選択して保存してください。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0
                    ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${currentMonth.year}年${currentMonth.month}月',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: _currentPage < _monthCount - 1
                    ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: calendarHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _monthCount,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final month = _monthForIndex(index);
                return _MonthGrid(
                  month: month,
                  startDate: _startDate,
                  endDate: _endDate,
                  selected: _selected,
                  persisted: _persisted,
                  onToggle: _toggle,
                  selectedColor: _service.closedDayColor,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.selected,
    required this.persisted,
    required this.onToggle,
    required this.selectedColor,
  });

  final DateTime month;
  final DateTime startDate;
  final DateTime endDate;
  final Set<DateTime> selected;
  final Set<DateTime> persisted;
  final ValueChanged<DateTime> onToggle;
  final Color selectedColor;

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _inRange(DateTime date) {
    final d = _normalize(date);
    return !d.isBefore(_normalize(startDate)) && !d.isAfter(_normalize(endDate));
  }

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];
    final theme = Theme.of(context);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final mondayBasedOffset = (first.weekday + 6) % 7;
    final gridStart = first.subtract(Duration(days: mondayBasedOffset));

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final date = _normalize(gridStart.add(Duration(days: index)));
              final isInMonth = date.month == month.month;
              final enabled = isInMonth && _inRange(date);
              final isSelected = selected.contains(date);
              final isPersisted = persisted.contains(date);

              final bgColor = isSelected ? selectedColor.withOpacity(0.25) : null;
              final borderColor = isSelected
                  ? selectedColor
                  : (isPersisted ? selectedColor.withOpacity(0.45) : null);

              return InkWell(
                onTap: enabled ? () => onToggle(date) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: borderColor == null
                        ? null
                        : Border.all(color: borderColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    date.day.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '対象期間：${startDate.year}年${startDate.month}月${startDate.day}日〜'
          '${endDate.year}年${endDate.month}月${endDate.day}日',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
