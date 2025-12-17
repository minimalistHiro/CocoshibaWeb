import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/auth/firebase_auth_service.dart';
import 'package:cocoshibaweb/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {}

  runApp(
    CocoshibaWebApp(
      auth: FirebaseAuthService(FirebaseAuth.instance),
    ),
  );
}
