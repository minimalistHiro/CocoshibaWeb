import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item.dart';

class MenuService {
  MenuService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _menusRef =>
      _firestore.collection('menus');

  Stream<List<MenuItem>> watchMenus() {
    return _menusRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(MenuItem.fromDocument).toList(growable: false),
        );
  }

  Future<MenuItem?> fetchMenu(String id) async {
    final doc = await _menusRef.doc(id).get();
    if (!doc.exists) return null;
    return MenuItem.fromDocument(doc);
  }

  Future<String> createMenu({
    required String name,
    required int price,
    required MenuCategory category,
    String? imageUrl,
  }) async {
    final doc = _menusRef.doc();
    await doc.set({
      'name': name.trim(),
      'price': price,
      'category': category.firestoreValue,
      'imageUrl': (imageUrl ?? '').trim().isEmpty ? null : imageUrl!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateMenu(
    String id, {
    required String name,
    required int price,
    required MenuCategory category,
    String? imageUrl,
  }) async {
    await _menusRef.doc(id).set({
      'name': name.trim(),
      'price': price,
      'category': category.firestoreValue,
      'imageUrl': (imageUrl ?? '').trim().isEmpty ? null : imageUrl!.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMenu(String id) => _menusRef.doc(id).delete();
}
