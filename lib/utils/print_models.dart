class PrintMonthData {
  const PrintMonthData({
    required this.monthLabel,
    required this.days,
  });

  final String monthLabel;
  final List<PrintDayData> days;
}

class PrintDayData {
  const PrintDayData({
    required this.dayLabel,
    required this.weekdayLabel,
    required this.events,
    required this.isClosedDay,
  });

  final String dayLabel;
  final String weekdayLabel;
  final List<PrintEventData> events;
  final bool isClosedDay;
}

class PrintEventData {
  const PrintEventData({
    required this.title,
    required this.timeLabel,
  });

  final String title;
  final String timeLabel;
}
