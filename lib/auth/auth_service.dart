abstract class AuthService {
  Stream<AuthUser?> get onAuthStateChanged;
  AuthUser? get currentUser;

  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  Future<void> updateLoginInfo({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> deleteAccount({String? passwordForReauth});
}

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
}
