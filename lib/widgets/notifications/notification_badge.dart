// lib/widgets/notifications/notification_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../screens/notifications_screen.dart';

class NotificationBadge extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: iconColor ?? Theme.of(context).appBarTheme.foregroundColor,
                size: iconSize,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    provider.unreadCount > 99 ? '99+' : provider.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Compact notification badge for use in smaller spaces
class CompactNotificationBadge extends StatelessWidget {
  final Color? badgeColor;
  final Color? textColor;

  const CompactNotificationBadge({
    super.key,
    this.badgeColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor ?? Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            provider.unreadCount > 99 ? '99+' : provider.unreadCount.toString(),
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

// Notification indicator dot (just shows if there are unread notifications)
class NotificationDot extends StatelessWidget {
  final double size;
  final Color? color;

  const NotificationDot({
    super.key,
    this.size = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? Colors.red,
            borderRadius: BorderRadius.circular(size / 2),
          ),
        );
      },
    );
  }
}