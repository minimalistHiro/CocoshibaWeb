import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters(<String, String>{
        'prompt': 'select_account',
      });

    if (!kIsWeb) {
      throw UnsupportedError('Google sign-in is only supported on web in this app.');
    }

    await _auth.signInWithPopup(provider);
  }

  @override
  Stream<AuthUser?> get onAuthStateChanged =>
      _auth.userChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final normalizedDisplayName = displayName?.trim();
    final normalizedPhotoUrl = photoUrl?.trim();

    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      await user.updateDisplayName(normalizedDisplayName);
    }

    if (normalizedPhotoUrl != null) {
      await user.updatePhotoURL(normalizedPhotoUrl.isEmpty ? null : normalizedPhotoUrl);
    }

    await user.reload();
  }

  @override
  Future<void> updateLoginInfo({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw StateError('Email is not available for re-authentication.');
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    await user.reload();
  }

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> deleteAccount({String? passwordForReauth}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (passwordForReauth != null && passwordForReauth.isNotEmpty) {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw StateError('Email is not available for re-authentication.');
      }
      final credential =
          EmailAuthProvider.credential(email: email, password: passwordForReauth);
      await user.reauthenticateWithCredential(credential);
    }

    await user.delete();
  }

  static AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
