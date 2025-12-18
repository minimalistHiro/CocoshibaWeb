import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClosedDaysService {
  ClosedDaysService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  static const int _closedDayColorValue = 0xFF9E9E9E;

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  String _docId(DateTime date) {
    final d = _normalize(date);
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return 'closed_${d.year}-$mm-$dd';
  }

  Future<Set<DateTime>> fetchClosedDays({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = Timestamp.fromDate(_normalize(startDate));
    final endExclusive =
        Timestamp.fromDate(_normalize(endDate).add(const Duration(days: 1)));

    final snapshot = await _eventsRef
        .where('isClosedDay', isEqualTo: true)
        .where('startDateTime', isGreaterThanOrEqualTo: start)
        .where('startDateTime', isLessThan: endExclusive)
        .orderBy('startDateTime')
        .get();

    final result = <DateTime>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final ts = data['startDateTime'];
      if (ts is Timestamp) {
        result.add(_normalize(ts.toDate()));
      }
    }
    return result;
  }

  Future<void> saveClosedDays(Set<DateTime> selectedDates) async {
    final normalized = selectedDates.map(_normalize).toSet();
    final batch = _firestore.batch();

    for (final date in normalized) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(hours: 23, minutes: 59));
      final ref = _eventsRef.doc(_docId(date));
      batch.set(ref, {
        'name': '定休日',
        'organizer': '',
        'startDateTime': Timestamp.fromDate(start),
        'endDateTime': Timestamp.fromDate(end),
        'content': '定休日のため休業です。',
        'imageUrls': const <String>[],
        'colorValue': _closedDayColorValue,
        'capacity': 0,
        'isClosedDay': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> deleteClosedDay(DateTime date) async {
    await _eventsRef.doc(_docId(date)).delete();
  }

  Color get closedDayColor => const Color(_closedDayColorValue);
}

