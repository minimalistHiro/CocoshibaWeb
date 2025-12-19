import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:cocoshibaweb/services/user_profile_service.dart';
import 'package:firebase_core/firebase_core.dart';

class OwnerService {
  OwnerService({UserProfileService? profileService})
      : _profileService = profileService ?? UserProfileService();

  final UserProfileService _profileService;

  static bool isOwnerFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    if (profile['isOwner'] == true) return true;
    final role = (profile['role'] as String?)?.trim().toLowerCase();
    if (role == 'owner') return true;
    final roles = profile['roles'];
    if (roles is List) {
      return roles.any((e) => e.toString().trim().toLowerCase() == 'owner');
    }
    return false;
  }

  Stream<bool> watchIsOwner(AuthUser? user) {
    if (user == null) return Stream.value(false);
    if (Firebase.apps.isEmpty) return Stream.value(false);
    return _profileService
        .watchProfile(user.uid)
        .map(isOwnerFromProfile)
        .handleError((_) => false);
  }
}

