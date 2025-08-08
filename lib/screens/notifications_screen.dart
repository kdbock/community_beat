// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../widgets/notifications/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize notifications if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.notifications)),
            Tab(text: 'Unread', icon: Icon(Icons.notifications_active)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isEmpty) return const SizedBox.shrink();
              
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  final scaffoldContext = context;
                  switch (value) {
                    case 'mark_all_read':
                      await provider.markAllAsRead();
                      if (mounted) {
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
                          ),
                        );
                      }
                      break;
                    case 'clear_all':
                      if (mounted) {
                        await _showClearAllDialog(scaffoldContext, provider);
                      }
                      break;
                    case 'test_notification':
                      await provider.sendTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification added'),
                          ),
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear all'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'test_notification',
                    child: Row(
                      children: [
                        Icon(Icons.bug_report),
                        SizedBox(width: 8),
                        Text('Send test notification'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllNotificationsTab(),
          _buildUnreadNotificationsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.notifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.notifications_none,
            title: 'No notifications yet',
            subtitle: 'When you receive notifications, they\'ll appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification, provider),
                onDismiss: () => provider.deleteNotification(notification.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUnreadNotificationsTab() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final unreadNotifications = provider.getUnreadNotifications();

        if (unreadNotifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.notifications_active,
            title: 'All caught up!',
            subtitle: 'You have no unread notifications',
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: unreadNotifications.length,
            itemBuilder: (context, index) {
              final notification = unreadNotifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification, provider),
                onDismiss: () => provider.deleteNotification(notification.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final categories = provider.getNotificationCategories();
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notification Preferences',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose which types of notifications you want to receive',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...categories.entries.map((entry) {
              return Card(
                child: SwitchListTile(
                  title: Text(entry.value),
                  subtitle: Text(_getCategoryDescription(entry.key)),
                  value: provider.isCategoryEnabled(entry.key),
                  onChanged: (value) {
                    provider.updatePreference(entry.key, value);
                  },
                  secondary: Icon(_getCategoryIcon(entry.key)),
                ),
              );
            }),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notification Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatsRow('Total notifications', provider.notifications.length.toString()),
                    _buildStatsRow('Unread notifications', provider.unreadCount.toString()),
                    const SizedBox(height: 8),
                    ...provider.getNotificationStats().entries.map((entry) {
                      return _buildStatsRow(
                        _getTypeDisplayName(entry.key),
                        entry.value.toString(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'events':
        return Icons.event;
      case 'alerts':
        return Icons.warning;
      case 'business':
        return Icons.business;
      case 'services':
        return Icons.build;
      case 'traffic':
        return Icons.traffic;
      case 'weather':
        return Icons.wb_sunny;
      case 'posts':
        return Icons.article;
      case 'service_requests':
        return Icons.support_agent;
      default:
        return Icons.notifications;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'events':
        return 'Community events and activities';
      case 'alerts':
        return 'Emergency and important alerts';
      case 'business':
        return 'Local business updates and promotions';
      case 'services':
        return 'Public services and utilities';
      case 'traffic':
        return 'Traffic conditions and road closures';
      case 'weather':
        return 'Weather warnings and updates';
      case 'posts':
        return 'New community posts and discussions';
      case 'service_requests':
        return 'Service request updates and responses';
      default:
        return 'General notifications';
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'event':
        return 'Events';
      case 'alert':
        return 'Alerts';
      case 'business':
        return 'Business';
      case 'post':
        return 'Posts';
      case 'service':
        return 'Services';
      case 'general':
        return 'General';
      default:
        return type.toUpperCase();
    }
  }

  void _handleNotificationTap(NotificationData notification, NotificationProvider provider) {
    // Mark as read if not already read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.event:
        // Navigate to event details
        _navigateToEvent(notification.data['event_id']);
        break;
      case NotificationType.alert:
        // Show alert details
        _showAlertDetails(notification);
        break;
      case NotificationType.business:
        // Navigate to business details
        _navigateToBusiness(notification.data['business_id']);
        break;
      case NotificationType.post:
        // Navigate to post details
        _navigateToPost(notification.data['post_id']);
        break;
      case NotificationType.service:
        // Navigate to service request details
        _navigateToServiceRequest(notification.data['service_id']);
        break;
      case NotificationType.general:
        // Show general notification details
        _showNotificationDetails(notification);
        break;
    }
  }

  void _navigateToEvent(String? eventId) {
    if (eventId != null) {
      // TODO: Navigate to event details screen
      debugPrint('Navigate to event: $eventId');
    }
  }

  void _navigateToBusiness(String? businessId) {
    if (businessId != null) {
      // TODO: Navigate to business details screen
      debugPrint('Navigate to business: $businessId');
    }
  }

  void _navigateToPost(String? postId) {
    if (postId != null) {
      // TODO: Navigate to post details screen
      debugPrint('Navigate to post: $postId');
    }
  }

  void _navigateToServiceRequest(String? serviceId) {
    if (serviceId != null) {
      // TODO: Navigate to service request details screen
      debugPrint('Navigate to service request: $serviceId');
    }
  }

  void _showAlertDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatTimestamp(notification.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _showClearAllDialog(BuildContext context, NotificationProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.clearAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared'),
        ),
      );
    }
  }
}