import 'dart:async';

import 'package:cocoshibaweb/auth/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService() {
    _controller.add(null);
  }

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  @override
  Stream<AuthUser?> get onAuthStateChanged => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithGoogle() async {
    _currentUser = const AuthUser(
      uid: 'google_uid',
      email: 'google@example.com',
      emailVerified: true,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return;
    _currentUser = AuthUser(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      emailVerified: _currentUser!.emailVerified,
      displayName: displayName ?? _currentUser!.displayName,
      photoUrl: photoUrl ?? _currentUser!.photoUrl,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<void> updateLoginInfo({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(
      uid: 'uid',
      email: email,
      emailVerified: false,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(
      uid: 'uid',
      email: email,
      emailVerified: false,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<void> sendEmailVerification({String? continueUrl}) async {}

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    String? continueUrl,
  }) async {}

  @override
  Future<String> verifyPasswordResetCode({required String code}) async => code;

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount({String? passwordForReauth}) async {
    _currentUser = null;
    _controller.add(null);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
