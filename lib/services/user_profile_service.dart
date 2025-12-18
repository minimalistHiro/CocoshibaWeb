import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    required String bio,
    String? photoUrl,
  }) async {
    await _profileRef(uid).set(
      {
        'name': name.trim(),
        'ageGroup': ageGroup,
        'area': area,
        'bio': bio.trim(),
        'photoUrl': (photoUrl ?? '').trim().isEmpty ? null : photoUrl!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

