import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _firebaseStatus = 'Checking Firebase...';
  String _fcmToken = 'Getting FCM token...';
  String _messagingStatus = 'Checking messaging...';

  @override
  void initState() {
    super.initState();
    _testFirebaseSetup();
  }

  Future<void> _testFirebaseSetup() async {
    try {
      // Test Firebase Core initialization
      if (Firebase.apps.isNotEmpty) {
        setState(() {
          _firebaseStatus = '✅ Firebase Core initialized successfully';
        });
      } else {
        setState(() {
          _firebaseStatus = '❌ Firebase Core not initialized';
        });
        return;
      }

      // Test Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        setState(() {
          _messagingStatus = '✅ Notification permissions granted';
        });
      } else {
        setState(() {
          _messagingStatus = '⚠️ Notification permissions denied';
        });
      }

      // Get FCM token
      String? token = await messaging.getToken();
      setState(() {
        _fcmToken = token != null 
          ? '✅ FCM Token: ${token.substring(0, 20)}...' 
          : '❌ Failed to get FCM token';
      });

    } catch (e) {
      setState(() {
        _firebaseStatus = '❌ Firebase setup error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Setup Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Setup Status:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_firebaseStatus),
                    const SizedBox(height: 8),
                    Text(_messagingStatus),
                    const SizedBox(height: 8),
                    Text(_fcmToken),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Project Configuration:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}'),
                    const SizedBox(height: 8),
                    Text('App ID: ${DefaultFirebaseOptions.currentPlatform.appId}'),
                    const SizedBox(height: 8),
                    Text('Messaging Sender ID: ${DefaultFirebaseOptions.currentPlatform.messagingSenderId}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testFirebaseSetup,
              child: const Text('Retest Firebase Setup'),
            ),
          ],
        ),
      ),
    );
  }
}