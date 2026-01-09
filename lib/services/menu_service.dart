import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item.dart';

class MenuService {
  MenuService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _menusRef =>
      _firestore.collection('menus');

  Stream<List<MenuItem>> watchMenus() {
    return _menusRef.orderBy('orderIndex').snapshots().map(
          (snapshot) =>
              snapshot.docs.map(MenuItem.fromDocument).toList(growable: false),
        );
  }
}
