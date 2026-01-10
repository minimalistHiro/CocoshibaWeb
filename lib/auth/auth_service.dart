abstract class AuthService {
  Stream<AuthUser?> get onAuthStateChanged;
  AuthUser? get currentUser;

  Future<void> signInWithGoogle();

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

  Future<void> sendEmailVerification({String? continueUrl});

  Future<void> reloadCurrentUser();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({
    required String email,
    String? continueUrl,
  });

  Future<String> verifyPasswordResetCode({required String code});

  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  });

  Future<void> deleteAccount({String? passwordForReauth});
}

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.displayName,
    this.photoUrl,
    this.providerIds = const {},
  });

  final String uid;
  final String? email;
  final bool emailVerified;
  final String? displayName;
  final String? photoUrl;
  final Set<String> providerIds;

  bool get isGoogleSignIn => providerIds.contains('google.com');
}
