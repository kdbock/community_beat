// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    if (!kIsWeb) {
      _messaging = FirebaseMessaging.instance;
      
      // Request permission for notifications
      await _requestPermission();
      
      // Get FCM token
      _fcmToken = await _messaging?.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Configure message handlers
      _configureMessageHandlers();
      
      // Subscribe to default topics
      await _subscribeToDefaultTopics();
    }
  }

  // Request notification permissions
  Future<void> _requestPermission() async {
    if (_messaging == null) return;

    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  // Configure message handlers
  void _configureMessageHandlers() {
    if (_messaging == null) return;

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background message: ${message.messageId}');
      _handleMessageTap(message);
    });

    // Handle messages when app is opened from terminated state
    _messaging!.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state: ${message.messageId}');
        _handleMessageTap(message);
      }
    });
  }

  // Handle foreground messages (show in-app notification)
  void _handleForegroundMessage(RemoteMessage message) {
    // You can show a custom in-app notification here
    // For now, we'll just print the message
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
  }

  // Handle message tap (navigate to relevant screen)
  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'event':
        // Navigate to event details
        debugPrint('Navigate to event: ${data['event_id']}');
        break;
      case 'alert':
        // Navigate to alerts screen
        debugPrint('Navigate to alerts');
        break;
      case 'business':
        // Navigate to business details
        debugPrint('Navigate to business: ${data['business_id']}');
        break;
      case 'post':
        // Navigate to post details
        debugPrint('Navigate to post: ${data['post_id']}');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  // Subscribe to default notification topics
  Future<void> _subscribeToDefaultTopics() async {
    if (_messaging == null) return;

    try {
      // Subscribe to general community updates
      await _messaging!.subscribeToTopic('community_updates');
      
      // Subscribe to emergency alerts
      await _messaging!.subscribeToTopic('emergency_alerts');
      
      debugPrint('Subscribed to default topics');
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }

  // Subscribe to specific topics
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;

    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;

    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  // Get FCM token
  String? get fcmToken => _fcmToken;

  // Refresh FCM token
  Future<String?> refreshToken() async {
    if (_messaging == null) return null;

    try {
      _fcmToken = await _messaging!.getToken();
      debugPrint('Refreshed FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }

  // Send token to server (for targeted notifications)
  Future<void> sendTokenToServer(String? userId) async {
    if (_fcmToken == null || userId == null) return;

    try {
      // TODO: Send token to your backend server
      // await ApiService().updateUserToken(userId, _fcmToken!);
      debugPrint('Token sent to server for user: $userId');
    } catch (e) {
      debugPrint('Error sending token to server: $e');
    }
  }

  // Show local notification (for testing)
  void showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    // This would typically use a local notification plugin
    // For now, we'll just show a debug message
    debugPrint('Local Notification - Title: $title, Body: $body');
  }

  // Notification categories for subscription management
  static const Map<String, String> notificationCategories = {
    'events': 'Community Events',
    'alerts': 'Emergency Alerts',
    'business': 'Business Updates',
    'services': 'Public Services',
    'traffic': 'Traffic Updates',
    'weather': 'Weather Alerts',
  };

  // Get available notification categories
  Map<String, String> getNotificationCategories() {
    return notificationCategories;
  }

  // Batch subscribe/unsubscribe to categories
  Future<void> updateSubscriptions(Map<String, bool> subscriptions) async {
    for (final entry in subscriptions.entries) {
      if (entry.value) {
        await subscribeToTopic(entry.key);
      } else {
        await unsubscribeFromTopic(entry.key);
      }
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

// Notification types for routing
enum NotificationType {
  event,
  alert,
  business,
  post,
  service,
  general,
}

// Notification data model
class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationData.fromRemoteMessage(RemoteMessage message) {
    return NotificationData(
      id: message.messageId ?? '',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      data: message.data,
      timestamp: DateTime.now(),
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'event':
        return NotificationType.event;
      case 'alert':
        return NotificationType.alert;
      case 'business':
        return NotificationType.business;
      case 'post':
        return NotificationType.post;
      case 'service':
        return NotificationType.service;
      default:
        return NotificationType.general;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _parseNotificationType(json['type']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }
}