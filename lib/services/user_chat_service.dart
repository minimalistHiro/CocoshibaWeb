import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_chat_models.dart';

class UserChatService {
  UserChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> sendMessage({
    required String threadId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final sender = _auth.currentUser;
    if (sender == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'ログインしていません',
      );
    }

    await _ensureThreadMetadata(threadId: threadId);

    final messagesRef =
        _firestore.collection('userChats').doc(threadId).collection('messages');
    final messageRef = messagesRef.doc();

    final senderName = (sender.displayName ?? sender.email ?? 'ユーザー').trim();
    final senderPhoto = (sender.photoURL ?? '').trim();

    await messageRef.set({
      'text': trimmed,
      'senderId': sender.uid,
      'senderName': senderName.isEmpty ? 'ユーザー' : senderName,
      'senderPhotoUrl': senderPhoto,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('userChats').doc(threadId).set(
      {
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': sender.uid,
        'lastMessageSenderName': senderName,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _ensureThreadMetadata({required String threadId}) async {
    final docRef = _firestore.collection('userChats').doc(threadId);
    final snapshot = await docRef.get();
    final hasUserName = snapshot.exists &&
        snapshot.data()?['userName'] != null &&
        (snapshot.data()?['userName'] as String).trim().isNotEmpty;

    if (hasUserName) return;

    final userDoc = await _firestore.collection('users').doc(threadId).get();
    final data = userDoc.data();

    final nameValue = data?['name'] as String?;
    final hasName = (nameValue?.trim().isNotEmpty ?? false);
    final userName = hasName ? nameValue!.trim() : 'ユーザー';
    final userPhoto = (data?['photoUrl'] as String?) ?? '';

    final payload = <String, dynamic>{
      'userId': threadId,
      'userName': userName,
      'userPhotoUrl': userPhoto,
    };

    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['lastMessageAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(payload, SetOptions(merge: true));
  }

  Stream<List<UserChatThread>> watchAllThreads() {
    return _firestore
        .collection('userChats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final updatedAt = data['lastMessageAt'] as Timestamp?;
        return UserChatThread(
          id: doc.id,
          userName: (data['userName'] as String?) ?? 'ユーザー',
          avatarUrl: (data['userPhotoUrl'] as String?) ?? '',
          lastMessage: (data['lastMessage'] as String?) ?? '',
          lastMessageSenderId: (data['lastMessageSenderId'] as String?) ?? '',
          updatedAt: updatedAt?.toDate(),
        );
      }).toList(growable: false);
    });
  }

  Stream<DateTime?> watchLastReadAt({
    required String threadId,
    required String viewerId,
  }) {
    return _firestore
        .collection('userChats')
        .doc(threadId)
        .collection('readStatus')
        .doc(viewerId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return (data?['lastReadAt'] as Timestamp?)?.toDate();
    });
  }

  Future<void> markThreadAsRead({
    required String threadId,
    required String viewerId,
  }) {
    return _firestore
        .collection('userChats')
        .doc(threadId)
        .collection('readStatus')
        .doc(viewerId)
        .set(
      {
        'lastReadAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<UserChatMessage>> watchMessages(String threadId) {
    return _firestore
        .collection('userChats')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        return UserChatMessage(
          id: doc.id,
          text: (data['text'] as String?) ?? '',
          senderId: (data['senderId'] as String?) ?? '',
          senderName: (data['senderName'] as String?) ?? '',
          senderPhotoUrl: (data['senderPhotoUrl'] as String?) ?? '',
          createdAt: createdAt?.toDate(),
        );
      }).toList(growable: false);
    });
  }
}

