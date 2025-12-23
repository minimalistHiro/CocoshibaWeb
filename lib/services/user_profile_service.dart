import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/local_image.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final snapshot = await _profileRef(uid).get();
    return snapshot.data();
  }

  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _profileRef(uid).snapshots().map((snapshot) => snapshot.data());
  }

  Future<void> upsertProfile(
    String uid, {
    required String name,
    required String ageGroup,
    required String area,
    required String gender,
    required String bio,
    String? photoUrl,
  }) async {
    await _profileRef(uid).set(
      {
        'name': name.trim(),
        'ageGroup': ageGroup,
        'area': area,
        'gender': gender,
        'bio': bio.trim(),
        'photoUrl': (photoUrl ?? '').trim().isEmpty ? null : photoUrl!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> uploadProfileImage(String uid, LocalImage image) async {
    final filename = image.filename.trim().isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
        : '${DateTime.now().millisecondsSinceEpoch}_${image.filename.trim()}';
    final ref = _storage.ref().child('profile_images/$uid/$filename');
    await ref.putData(
      image.bytes,
      SettableMetadata(contentType: image.contentType),
    );
    return ref.getDownloadURL();
  }
}
