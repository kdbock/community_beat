import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase messaging notification handler
class NotificationHandler {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static BuildContext? _context;

  static Future<void> initialize(BuildContext context) async {
    _context = context;

    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get the token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle terminated app messages
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    if (_context != null) {
      _showNotificationDialog(_context!, message);
    }
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    // Handle navigation based on message data
    print('Background message: ${message.data}');
    // Navigate to specific screen based on message type
  }

  static void _showNotificationDialog(BuildContext context, RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? 'You have a new notification'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          if (message.data.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNotificationAction(context, message.data);
              },
              child: const Text('View'),
            ),
        ],
      ),
    );
  }

  static void _handleNotificationAction(BuildContext context, Map<String, dynamic> data) {
    // Handle different notification types
    String? type = data['type'];
    switch (type) {
      case 'news':
        // Navigate to news detail
        break;
      case 'event':
        // Navigate to event detail
        break;
      case 'business':
        // Navigate to business detail
        break;
      case 'post':
        // Navigate to post detail
        break;
      default:
        // Default action
        break;
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

/// Local notification widget for in-app notifications
class InAppNotification extends StatefulWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotification({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.duration = const Duration(seconds: 4),
    this.onTap,
    this.onDismiss,
  });

  @override
  State<InAppNotification> createState() => _InAppNotificationState();

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: InAppNotification(
          title: title,
          message: message,
          icon: icon,
          backgroundColor: backgroundColor,
          duration: duration,
          onTap: onTap,
          onDismiss: () => overlayEntry.remove(),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _InAppNotificationState extends State<InAppNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              widget.onTap?.call();
              _dismiss();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }
}