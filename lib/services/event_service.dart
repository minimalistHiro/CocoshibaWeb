import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/calendar_event.dart';

class EventService {
  EventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  Stream<List<CalendarEvent>> watchEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final startTimestamp = Timestamp.fromDate(
      DateTime(startDate.year, startDate.month, startDate.day),
    );
    final endTimestamp = Timestamp.fromDate(
      DateTime(endDate.year, endDate.month, endDate.day).add(
        const Duration(days: 1),
      ),
    );

    return _eventsRef
        .where('startDateTime', isGreaterThanOrEqualTo: startTimestamp)
        .where('startDateTime', isLessThan: endTimestamp)
        .orderBy('startDateTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CalendarEvent.fromDocument)
              .toList(growable: false),
        );
  }
}
