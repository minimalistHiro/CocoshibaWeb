import 'package:cocoshibaweb/auth/auth_service.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const cocoshibaMainColor = Color(0xFF2E9463);
const cocoshibaSubColor = Color(0xFFFFFBD2);
const cocoshibaBackgroundColor = Colors.white;
const storeDisplayName = 'Antenna Books & Cafe ココシバ';

class CocoshibaWebApp extends StatefulWidget {
  const CocoshibaWebApp({super.key, required this.auth});

  final AuthService auth;

  @override
  State<CocoshibaWebApp> createState() => _CocoshibaWebAppState();
}

class _CocoshibaWebAppState extends State<CocoshibaWebApp> {
  late final AuthRefreshNotifier _authRefreshNotifier;
  late final CocoshibaRouter _router;

  @override
  void initState() {
    super.initState();
    _authRefreshNotifier = AuthRefreshNotifier(widget.auth.onAuthStateChanged);
    _router = CocoshibaRouter(
      auth: widget.auth,
      authRefreshNotifier: _authRefreshNotifier,
    );
  }

  @override
  void dispose() {
    _authRefreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: cocoshibaMainColor,
      brightness: Brightness.light,
    );
    final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;

    return AppServices(
      auth: widget.auth,
      child: MaterialApp.router(
        title: storeDisplayName,
        theme: ThemeData(
          colorScheme: baseColorScheme.copyWith(
            surface: cocoshibaBackgroundColor,
            secondaryContainer: cocoshibaSubColor,
          ),
          scaffoldBackgroundColor: cocoshibaBackgroundColor,
          textTheme: GoogleFonts.sawarabiMinchoTextTheme(baseTextTheme),
          useMaterial3: true,
        ),
        routerConfig: _router.router,
      ),
    );
  }
}

class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.auth,
    required super.child,
  });

  final AuthService auth;

  static AppServices of(BuildContext context) {
    final services = context.dependOnInheritedWidgetOfExactType<AppServices>();
    if (services == null) {
      throw StateError('AppServices not found in widget tree.');
    }
    return services;
  }

  @override
  bool updateShouldNotify(covariant AppServices oldWidget) =>
      auth != oldWidget.auth;
}
