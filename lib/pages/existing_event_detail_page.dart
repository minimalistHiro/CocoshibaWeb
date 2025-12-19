import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/pages/event_detail_page.dart';
import 'package:flutter/material.dart';

class ExistingEventDetailPage extends StatelessWidget {
  const ExistingEventDetailPage({super.key, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return EventDetailPage(
      event: event,
      isExistingEvent: true,
      title: '既存イベント詳細',
      showReservationActions: false,
      showScheduleInfo: false,
    );
  }
}
