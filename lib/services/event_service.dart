import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/calendar_event.dart';
import '../models/local_image.dart';

class EventService {
  EventService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> get _existingEventsRef =>
      _firestore.collection('existing_events');

  DocumentReference<Map<String, dynamic>> _eventDoc(
    String eventId, {
    required bool isExistingEvent,
  }) {
    return (isExistingEvent ? _existingEventsRef : _eventsRef).doc(eventId);
  }

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

  Stream<List<CalendarEvent>> watchUpcomingActiveEvents({int limit = 30}) {
    final now = DateTime.now();
    final startTimestamp = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );

    Query<Map<String, dynamic>> query = _eventsRef
        .where('startDateTime', isGreaterThanOrEqualTo: startTimestamp)
        .orderBy('startDateTime');

    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(CalendarEvent.fromDocument)
              .where((event) => !event.isClosedDay)
              .toList(growable: false),
        );
  }

  Stream<List<CalendarEvent>> watchAllEvents({bool descending = true}) {
    return _eventsRef
        .orderBy('startDateTime', descending: descending)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CalendarEvent.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<List<CalendarEvent>> watchEventsByExistingEventId(
    String existingEventId, {
    bool descending = false,
  }) {
    if (existingEventId.trim().isEmpty) {
      return Stream.value(const <CalendarEvent>[]);
    }
    return _eventsRef
        .where('existingEventId', isEqualTo: existingEventId)
        .orderBy('startDateTime', descending: descending)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CalendarEvent.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<List<CalendarEvent>> watchAllExistingEvents({bool descending = true}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return _existingEventsRef.snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final event = CalendarEvent.fromDocument(doc);
        final createdAt = parseDate(data['createdAt']);
        final start = event.startDateTime;
        final fallback =
            start.millisecondsSinceEpoch == 0 ? createdAt : start.toLocal();
        return (
          event: event,
          orderIndex: event.orderIndex,
          fallback: fallback,
        );
      }).toList();

      items.sort((a, b) {
        const maxIndex = 1 << 30;
        final aIndex = a.orderIndex ?? maxIndex;
        final bIndex = b.orderIndex ?? maxIndex;
        if (aIndex != bIndex) {
          final cmp = aIndex.compareTo(bIndex);
          return descending ? -cmp : cmp;
        }
        final cmp = a.fallback.compareTo(b.fallback);
        return descending ? -cmp : cmp;
      });

      return items.map((item) => item.event).toList(growable: false);
    });
  }

  Future<String> createEvent({
    required String name,
    required String organizer,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String content,
    required List<String> imageUrls,
    required int colorValue,
    required int capacity,
    List<LocalImage> images = const <LocalImage>[],
    bool isClosedDay = false,
    String? existingEventId,
  }) async {
    final docRef = _eventsRef.doc();
    final uploadedUrls = await _uploadEventImages(docRef.id, images);
    final mergedUrls = <String>[
      ...imageUrls,
      ...uploadedUrls,
    ];

    await docRef.set({
      'name': name.trim(),
      'organizer': organizer.trim(),
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'content': content.trim(),
      'imageUrls': mergedUrls,
      'colorValue': colorValue,
      'capacity': capacity,
      'isClosedDay': isClosedDay,
      'existingEventId': (existingEventId ?? '').trim().isEmpty
          ? null
          : existingEventId!.trim(),
      'reservationCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> deleteEvent(String eventId) async {
    final docRef = _eventsRef.doc(eventId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? const <String, dynamic>{};
    final urls = (data['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(growable: false) ??
        const <String>[];

    for (final url in urls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        // ignore cleanup failures
      }
    }

    await _deleteSubcollection(docRef.collection('event_reservations'));
    await docRef.delete();
  }

  Future<void> deleteExistingEvent(String eventId) async {
    final docRef = _existingEventsRef.doc(eventId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? const <String, dynamic>{};
    final urls = (data['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(growable: false) ??
        const <String>[];

    for (final url in urls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        // ignore cleanup failures
      }
    }

    await docRef.delete();
  }

  Future<CalendarEvent> updateEvent({
    required String eventId,
    required bool isExistingEvent,
    required String name,
    required String organizer,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String content,
    required List<String> imageUrls,
    required int colorValue,
    required int capacity,
    List<LocalImage> images = const <LocalImage>[],
    bool isClosedDay = false,
    String? existingEventId,
  }) async {
    final docRef = _eventDoc(eventId, isExistingEvent: isExistingEvent);
    final beforeSnapshot = await docRef.get();
    final beforeData = beforeSnapshot.data() ?? const <String, dynamic>{};
    final beforeUrls = (beforeData['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toSet() ??
        <String>{};

    final uploadedUrls = await _uploadEventImages(eventId, images);
    final mergedUrls = <String>[
      ...imageUrls.where((e) => e.trim().isNotEmpty),
      ...uploadedUrls,
    ];

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'organizer': organizer.trim(),
      'content': content.trim(),
      'imageUrls': mergedUrls,
      'colorValue': colorValue,
      'capacity': capacity,
      'isClosedDay': isClosedDay,
      'existingEventId': (existingEventId ?? '').trim().isEmpty
          ? null
          : existingEventId!.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!isExistingEvent) {
      updateData['startDateTime'] = Timestamp.fromDate(startDateTime);
      updateData['endDateTime'] = Timestamp.fromDate(endDateTime);
    }

    await docRef.set(updateData, SetOptions(merge: true));

    final afterUrlSet = mergedUrls.toSet();
    final removedUrls = beforeUrls.difference(afterUrlSet);
    for (final url in removedUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        // ignore cleanup failures
      }
    }

    final afterSnapshot = await docRef.get();
    return CalendarEvent.fromDocument(afterSnapshot);
  }

  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    while (true) {
      final snapshot = await ref.limit(100).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<List<String>> _uploadEventImages(
    String eventId,
    List<LocalImage> images,
  ) async {
    if (images.isEmpty) return const <String>[];

    final uploaded = <String>[];
    for (final image in images) {
      final filename = image.filename.trim().isEmpty
          ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
          : '${DateTime.now().millisecondsSinceEpoch}_${image.filename.trim()}';
      final ref = _storage.ref().child('event_images/$eventId/$filename');
      final task = await ref.putData(
        image.bytes,
        SettableMetadata(contentType: image.contentType),
      );
      final url = await task.ref.getDownloadURL();
      uploaded.add(url);
    }
    return uploaded;
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

  Stream<List<CalendarEvent>> watchReservedEvents(
    String userId, {
    DateTime? startDateTime,
  }) {
    Query<Map<String, dynamic>> query = _userReservationsRef(userId);
    if (startDateTime != null) {
      query = query.where(
        'eventStartDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDateTime),
      );
    }
    query = query.orderBy('eventStartDateTime');

    return query.snapshots().asyncMap((snapshot) async {
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
