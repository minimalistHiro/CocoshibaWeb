import 'dart:async';

import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:cocoshibaweb/pages/calendar_page.dart';
import 'package:cocoshibaweb/pages/book_order_page.dart';
import 'package:cocoshibaweb/pages/data_privacy_page.dart';
import 'package:cocoshibaweb/pages/faq_page.dart';
import 'package:cocoshibaweb/pages/account_info_register_page.dart';
import 'package:cocoshibaweb/pages/event_create_page.dart';
import 'package:cocoshibaweb/pages/events_page.dart';
import 'package:cocoshibaweb/pages/home_page.dart';
import 'package:cocoshibaweb/pages/login_info_update_page.dart';
import 'package:cocoshibaweb/pages/login_page.dart';
import 'package:cocoshibaweb/pages/menu_page.dart';
import 'package:cocoshibaweb/pages/email_verification_page.dart';
import 'package:cocoshibaweb/pages/password_reset_page.dart';
import 'package:cocoshibaweb/pages/password_reset_sent_page.dart';
import 'package:cocoshibaweb/pages/profile_edit_page.dart';
import 'package:cocoshibaweb/pages/privacy_policy_page.dart';
import 'package:cocoshibaweb/pages/signup_page.dart';
import 'package:cocoshibaweb/pages/store_page.dart';
import 'package:cocoshibaweb/pages/support_help_page.dart';
import 'package:cocoshibaweb/pages/terms_page.dart';
import 'package:cocoshibaweb/widgets/app_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CocoshibaPaths {
  static const home = '/';
  static const events = '/events';
  static const calendar = '/calendar';
  static const menu = '/menu';
  static const bookOrder = '/book-order';
  static const store = '/store';

  static const calendarEventCreate = '/_/calendar/events/new';

  static const login = '/_/login';
  static const signup = '/_/signup';
  static const signupVerify = '/_/signup/verify';
  static const passwordReset = '/_/password-reset';
  static const passwordResetSent = '/_/password-reset/sent';
  static const profileEdit = '/_/profile/edit';
  static const loginInfoUpdate = '/_/login-info';
  static const accountInfoRegister = '/_/account-info';
  static const dataPrivacy = '/_/data-privacy';
  static const supportHelp = '/_/support';
  static const faq = '/_/faq';
  static const terms = '/_/terms';
  static const privacyPolicy = '/_/privacy-policy';
}

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Stream<AuthUser?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthUser?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class CocoshibaRouter {
  CocoshibaRouter({
    required AuthService auth,
    required AuthRefreshNotifier authRefreshNotifier,
  }) : router = GoRouter(
          initialLocation: CocoshibaPaths.home,
          refreshListenable: authRefreshNotifier,
          redirect: (context, state) {
            final user = auth.currentUser;
            final isLoggedIn = user != null;
            final isEmailVerified = user?.emailVerified ?? true;
            final path = state.matchedLocation;

            final isAuthPage =
                path == CocoshibaPaths.login || path == CocoshibaPaths.signup;
            final isVerificationPage = path == CocoshibaPaths.signupVerify;

            if (isLoggedIn && !isEmailVerified && !isVerificationPage) {
              final from = Uri.encodeComponent(state.uri.toString());
              return '${CocoshibaPaths.signupVerify}?from=$from';
            }

            if (isLoggedIn && isAuthPage) {
              final rawFrom = state.uri.queryParameters['from'];
              if (rawFrom != null && rawFrom.isNotEmpty) {
                return Uri.decodeComponent(rawFrom);
              }
              return CocoshibaPaths.home;
            }

            return null;
          },
          routes: [
            ShellRoute(
              builder: (context, state, child) => AppScaffold(child: child),
              routes: [
                GoRoute(
                  path: CocoshibaPaths.home,
                  builder: (context, state) => const HomePage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.events,
                  builder: (context, state) => const EventsPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.calendar,
                  builder: (context, state) => const CalendarPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.calendarEventCreate,
                  builder: (context, state) {
                    DateTime? initialDate;
                    final raw = state.uri.queryParameters['date'];
                    if (raw != null && raw.isNotEmpty) {
                      final parts = raw.split('-');
                      if (parts.length == 3) {
                        final year = int.tryParse(parts[0]);
                        final month = int.tryParse(parts[1]);
                        final day = int.tryParse(parts[2]);
                        if (year != null && month != null && day != null) {
                          initialDate = DateTime(year, month, day);
                        }
                      }
                    }
                    return EventCreatePage(initialDate: initialDate);
                  },
                ),
                GoRoute(
                  path: CocoshibaPaths.menu,
                  builder: (context, state) => const MenuPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.bookOrder,
                  builder: (context, state) => const BookOrderPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.store,
                  builder: (context, state) => const StorePage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.login,
                  builder: (context, state) => LoginPage(
                    from: state.uri.queryParameters['from'],
                  ),
                ),
                GoRoute(
                  path: CocoshibaPaths.signup,
                  builder: (context, state) => SignupPage(
                    from: state.uri.queryParameters['from'],
                  ),
                ),
                GoRoute(
                  path: CocoshibaPaths.signupVerify,
                  builder: (context, state) => EmailVerificationPage(
                    email: state.uri.queryParameters['email'],
                    from: state.uri.queryParameters['from'],
                  ),
                ),
                GoRoute(
                  path: CocoshibaPaths.passwordReset,
                  builder: (context, state) => PasswordResetPage(
                    oobCode: state.uri.queryParameters['oobCode'],
                    mode: state.uri.queryParameters['mode'],
                  ),
                ),
                GoRoute(
                  path: CocoshibaPaths.passwordResetSent,
                  builder: (context, state) => PasswordResetSentPage(
                    email: state.uri.queryParameters['email'],
                  ),
                ),
                GoRoute(
                  path: CocoshibaPaths.profileEdit,
                  builder: (context, state) => const ProfileEditPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.accountInfoRegister,
                  builder: (context, state) => AccountInfoRegisterPage(
                    from: state.uri.queryParameters['from'],
                  ),
                ),
                GoRoute(
                  path: CocoshibaPaths.loginInfoUpdate,
                  builder: (context, state) => const LoginInfoUpdatePage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.dataPrivacy,
                  builder: (context, state) => const DataPrivacyPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.supportHelp,
                  builder: (context, state) => const SupportHelpPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.faq,
                  builder: (context, state) => const FaqPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.terms,
                  builder: (context, state) => const TermsPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.privacyPolicy,
                  builder: (context, state) => const PrivacyPolicyPage(),
                ),
              ],
            ),
          ],
          errorBuilder: (context, state) => AppScaffold(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ページが見つかりません',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'URL: ${state.uri}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go(CocoshibaPaths.home),
                        child: const Text('ホームへ戻る'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          debugLogDiagnostics: kDebugMode,
        );

  final GoRouter router;
}
