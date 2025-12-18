import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/calendar_event.dart';

class EventService {
  EventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> _userReservationsRef(
          String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('event_reservations');

  CollectionReference<Map<String, dynamic>> _eventReservationsRef(
          String eventId) =>
      _eventsRef.doc(eventId).collection('event_reservations');

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

  Stream<List<CalendarEvent>> watchUpcomingEvents({int limit = 7}) {
    final now = DateTime.now();
    final startTimestamp = Timestamp.fromDate(now);

    return _eventsRef
        .where('startDateTime', isGreaterThanOrEqualTo: startTimestamp)
        .orderBy('startDateTime')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CalendarEvent.fromDocument)
              .toList(growable: false),
        );
  }

  Future<bool> hasReservation({
    required String eventId,
    required String userId,
  }) async {
    final doc = await _userReservationsRef(userId).doc(eventId).get();
    return doc.exists;
  }

  Future<void> reserveEvent({
    required CalendarEvent event,
    required String userId,
    String? userEmail,
  }) async {
    final reservationRef = _userReservationsRef(userId).doc(event.id);
    final eventReservationRef = _eventReservationsRef(event.id).doc(userId);
    final eventRef = _eventsRef.doc(event.id);

    await _firestore.runTransaction((transaction) async {
      final reservationSnapshot = await transaction.get(reservationRef);
      final eventReservationSnapshot =
          await transaction.get(eventReservationRef);
      if (reservationSnapshot.exists || eventReservationSnapshot.exists) {
        return;
      }

      transaction.set(reservationRef, {
        'userId': userId,
        'eventId': event.id,
        'eventName': event.name,
        'eventStartDateTime': Timestamp.fromDate(event.startDateTime),
        'eventEndDateTime': Timestamp.fromDate(event.endDateTime),
        'reservedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(eventReservationRef, {
        'userId': userId,
        'userEmail':
            (userEmail ?? '').trim().isEmpty ? null : userEmail?.trim(),
        'reservedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(eventRef, {
        'reservationCount': FieldValue.increment(1),
      });
    });
  }

  Future<void> cancelReservation({
    required String eventId,
    required String userId,
  }) async {
    final reservationRef = _userReservationsRef(userId).doc(eventId);
    final eventReservationRef = _eventReservationsRef(eventId).doc(userId);
    final eventRef = _eventsRef.doc(eventId);

    await _firestore.runTransaction((transaction) async {
      final reservationSnapshot = await transaction.get(reservationRef);
      if (!reservationSnapshot.exists) {
        return;
      }

      final eventSnapshot = await transaction.get(eventRef);
      transaction.delete(reservationRef);
      transaction.delete(eventReservationRef);

      final currentCount =
          (eventSnapshot.data()?['reservationCount'] as int?) ?? 0;
      if (currentCount > 0) {
        transaction.update(eventRef, {
          'reservationCount': FieldValue.increment(-1),
        });
      }
    });
  }

  Stream<int> watchEventReservationCount(String eventId) async* {
    final docRef = _eventsRef.doc(eventId);
    await for (final snapshot in docRef.snapshots()) {
      if (!snapshot.exists) {
        yield 0;
        continue;
      }

      final data = snapshot.data();
      final storedCount = data?['reservationCount'] as int?;
      if (storedCount != null) {
        yield storedCount;
        continue;
      }

      final countSnapshot = await _eventReservationsRef(eventId).get();
      final computedCount = countSnapshot.size;

      await docRef.set(
        {'reservationCount': computedCount},
        SetOptions(merge: true),
      );
      yield computedCount;
    }
  }

  Stream<List<CalendarEvent>> watchReservedEvents(String userId) {
    return _userReservationsRef(userId)
        .orderBy('eventStartDateTime')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return const <CalendarEvent>[];
      final eventIds = snapshot.docs.map((doc) => doc.id).toSet();
      if (eventIds.isEmpty) return const <CalendarEvent>[];

      final futures = eventIds.map((id) => _eventsRef.doc(id).get());
      final docs = await Future.wait(futures);
      final events = docs
          .where((doc) => doc.exists)
          .map(CalendarEvent.fromDocument)
          .where((event) => !event.isClosedDay)
          .toList(growable: false);
      events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      return events;
    });
  }
}
