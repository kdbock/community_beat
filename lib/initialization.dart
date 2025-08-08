import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

class AppInitializer {
  static bool _isInitialized = false;

  /// Initialize all app services
  static Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('[AppInitializer] Already initialized');
      return true;
    }

    try {
      // Initialize Flutter bindings first
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('[AppInitializer] Flutter bindings initialized');

      // Load environment variables
      await dotenv.load();
      debugPrint('[AppInitializer] Environment variables loaded');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[AppInitializer] Firebase initialized');

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();
      debugPrint('[AppInitializer] Firebase Messaging initialized');

      _isInitialized = true;
      return true;
    } catch (e, stack) {
      debugPrint('[AppInitializer] Initialization error: $e');
      debugPrint(stack.toString());
      return false;
    }
  }

  static Future<void> _initializeFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get FCM token
    final token = await messaging.getToken();
    debugPrint('[AppInitializer] FCM Token: $token');
  }
}
