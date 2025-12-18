import 'dart:async';

import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:cocoshibaweb/pages/calendar_page.dart';
import 'package:cocoshibaweb/pages/book_order_page.dart';
import 'package:cocoshibaweb/pages/faq_page.dart';
import 'package:cocoshibaweb/pages/events_page.dart';
import 'package:cocoshibaweb/pages/home_page.dart';
import 'package:cocoshibaweb/pages/login_info_update_page.dart';
import 'package:cocoshibaweb/pages/login_page.dart';
import 'package:cocoshibaweb/pages/menu_page.dart';
import 'package:cocoshibaweb/pages/admin/closed_days_settings_page.dart';
import 'package:cocoshibaweb/pages/admin/existing_event_form_page.dart';
import 'package:cocoshibaweb/pages/admin/existing_events_page.dart';
import 'package:cocoshibaweb/pages/admin/menu_form_page.dart';
import 'package:cocoshibaweb/pages/admin/menu_management_page.dart';
import 'package:cocoshibaweb/pages/admin/owner_settings_page.dart';
import 'package:cocoshibaweb/pages/admin/user_chat_support_page.dart';
import 'package:cocoshibaweb/pages/admin/user_chat_thread_page.dart';
import 'package:cocoshibaweb/pages/profile_edit_page.dart';
import 'package:cocoshibaweb/pages/signup_page.dart';
import 'package:cocoshibaweb/pages/store_page.dart';
import 'package:cocoshibaweb/pages/support_help_page.dart';
import 'package:cocoshibaweb/widgets/app_scaffold.dart';
import 'package:cocoshibaweb/models/user_chat_models.dart';
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

  static const login = '/_/login';
  static const signup = '/_/signup';
  static const profileEdit = '/_/profile/edit';
  static const loginInfoUpdate = '/_/login-info';
  static const supportHelp = '/_/support';
  static const faq = '/_/faq';

  static const adminChat = '/_/admin/chat';
  static const adminClosedDays = '/_/admin/closed-days';
  static const adminOwnerSettings = '/_/admin/owner-settings';
  static const adminMenu = '/_/admin/menu';
  static const adminExistingEvents = '/_/admin/existing-events';
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
            final isLoggedIn = auth.currentUser != null;
            final path = state.matchedLocation;

            final isAuthPage =
                path == CocoshibaPaths.login || path == CocoshibaPaths.signup;

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
                  path: CocoshibaPaths.profileEdit,
                  builder: (context, state) => const ProfileEditPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.loginInfoUpdate,
                  builder: (context, state) => const LoginInfoUpdatePage(),
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
                  path: CocoshibaPaths.adminChat,
                  builder: (context, state) => UserChatSupportPage(),
                  routes: [
                    GoRoute(
                      path: ':threadId',
                      builder: (context, state) => UserChatThreadPage(
                        threadId: state.pathParameters['threadId'] ?? '',
                        initialThread: state.extra is UserChatThread
                            ? state.extra as UserChatThread
                            : null,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: CocoshibaPaths.adminClosedDays,
                  builder: (context, state) => const ClosedDaysSettingsPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.adminOwnerSettings,
                  builder: (context, state) => const OwnerSettingsPage(),
                ),
                GoRoute(
                  path: CocoshibaPaths.adminMenu,
                  builder: (context, state) => const MenuManagementPage(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const MenuFormPage(),
                    ),
                    GoRoute(
                      path: 'edit/:id',
                      builder: (context, state) => MenuFormPage(
                        menuId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: CocoshibaPaths.adminExistingEvents,
                  builder: (context, state) => const ExistingEventsPage(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const ExistingEventFormPage(),
                    ),
                    GoRoute(
                      path: 'edit/:id',
                      builder: (context, state) => ExistingEventFormPage(
                        eventId: state.pathParameters['id'],
                      ),
                    ),
                  ],
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
