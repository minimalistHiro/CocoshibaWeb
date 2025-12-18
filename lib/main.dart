import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/auth/firebase_auth_service.dart';
import 'package:cocoshibaweb/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Explicitly register the Firestore web implementation to avoid falling back
  // to the (unsupported) method-channel codec on Flutter web, which triggers
  // the "Int64 accessor not supported by dart2js" error.
  FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
  try {
    usePathUrlStrategy();
  } catch (_) {
    // Hot restart on web can re-run main() without a full page reload.
    // In that case URL strategy is already set and Flutter throws.
  }

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
