import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AuthUser?> get onAuthStateChanged =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

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
    return AuthUser(uid: user.uid, email: user.email);
  }
}

