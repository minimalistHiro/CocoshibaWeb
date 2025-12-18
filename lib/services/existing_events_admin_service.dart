import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

class ExistingEventsAdminService {
  ExistingEventsAdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('existing_events');

  Stream<List<CalendarEvent>> watchExistingEvents({bool descending = true}) {
    return _ref
        .orderBy('startDateTime', descending: descending)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(CalendarEvent.fromDocument)
            .toList(growable: false));
  }

  Future<CalendarEvent?> fetchExistingEvent(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return CalendarEvent.fromDocument(doc);
  }

  Future<String> createExistingEvent({
    required String name,
    required String organizer,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String content,
    required List<String> imageUrls,
    required int colorValue,
    required int capacity,
  }) async {
    final doc = _ref.doc();
    await doc.set({
      'name': name.trim(),
      'organizer': organizer.trim(),
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'content': content.trim(),
      'imageUrls': imageUrls,
      'colorValue': colorValue,
      'capacity': capacity,
      'isClosedDay': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateExistingEvent(
    String id, {
    required String name,
    required String organizer,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String content,
    required List<String> imageUrls,
    required int colorValue,
    required int capacity,
  }) async {
    await _ref.doc(id).set({
      'name': name.trim(),
      'organizer': organizer.trim(),
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'content': content.trim(),
      'imageUrls': imageUrls,
      'colorValue': colorValue,
      'capacity': capacity,
      'isClosedDay': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteExistingEvent(String id) => _ref.doc(id).delete();

  static Color colorFromValue(int value) => Color(value);
}

