import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@immutable
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.name,
    required this.organizer,
    required this.startDateTime,
    required this.endDateTime,
    required this.content,
    required this.imageUrls,
    required this.colorValue,
    required this.capacity,
    required this.isClosedDay,
    this.existingEventId,
    this.orderIndex,
  });

  final String id;
  final String name;
  final String organizer;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String content;
  final List<String> imageUrls;
  final int colorValue;
  final int capacity;
  final bool isClosedDay;
  final String? existingEventId;
  final int? orderIndex;

  Color get color => Color(colorValue);

  factory CalendarEvent.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return CalendarEvent(
      id: doc.id,
      name: data['name'] as String? ?? '',
      organizer: data['organizer'] as String? ?? '',
      startDateTime: parseDate(data['startDateTime']),
      endDateTime: parseDate(data['endDateTime']),
      content: data['content'] as String? ?? '',
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      colorValue: (data['colorValue'] as int?) ?? Colors.blue.value,
      capacity: (data['capacity'] as int?) ?? 0,
      isClosedDay: data['isClosedDay'] == true,
      existingEventId: data['existingEventId'] as String?,
      orderIndex: (data['orderIndex'] as num?)?.toInt(),
    );
  }
}
