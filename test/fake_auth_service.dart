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
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(uid: 'uid', email: email);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(uid: 'uid', email: email);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> deleteAccount({String? passwordForReauth}) async {
    _currentUser = null;
    _controller.add(null);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

