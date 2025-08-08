// lib/providers/notification_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'dart:convert';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationData> _notifications = [];
  Map<String, bool> _preferences = {};
  bool _isLoading = false;
  int _unreadCount = 0;

  // Getters
  List<NotificationData> get notifications => _notifications;
  Map<String, bool> get preferences => _preferences;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load notification preferences
      await _loadPreferences();
      
      // Load notification history
      await _loadNotificationHistory();
      
      // Initialize notification service
      await _notificationService.initialize();
      
      // Update subscription preferences
      await _updateSubscriptions();
      
    } catch (e) {
      debugPrint('Error initializing notification provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notification preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString('notification_preferences');
      
      if (prefsString != null) {
        final Map<String, dynamic> prefsMap = json.decode(prefsString);
        _preferences = prefsMap.map((key, value) => MapEntry(key, value as bool));
      } else {
        // Set default preferences
        _preferences = {
          'events': true,
          'alerts': true,
          'business': true,
          'services': true,
          'traffic': false,
          'weather': true,
          'posts': true,
          'service_requests': true,
        };
        await _savePreferences();
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      // Set default preferences on error
      _preferences = {
        'events': true,
        'alerts': true,
        'business': true,
        'services': true,
        'traffic': false,
        'weather': true,
        'posts': true,
        'service_requests': true,
      };
    }
  }

  // Save notification preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_preferences', json.encode(_preferences));
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  // Load notification history from local storage
  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('notification_history');
      
      if (historyString != null) {
        final List<dynamic> historyList = json.decode(historyString);
        _notifications = historyList
            .map((item) => NotificationData.fromJson(item))
            .toList();
        
        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Calculate unread count
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('Error loading notification history: $e');
      _notifications = [];
      _unreadCount = 0;
    }
  }

  // Save notification history to local storage
  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notification_history', json.encode(historyList));
    } catch (e) {
      debugPrint('Error saving notification history: $e');
    }
  }

  // Update subscription preferences with notification service
  Future<void> _updateSubscriptions() async {
    try {
      await _notificationService.updateSubscriptions(_preferences);
    } catch (e) {
      debugPrint('Error updating subscriptions: $e');
    }
  }

  // Update a specific notification preference
  Future<void> updatePreference(String category, bool enabled) async {
    _preferences[category] = enabled;
    await _savePreferences();
    await _updateSubscriptions();
    notifyListeners();
  }

  // Update multiple preferences at once
  Future<void> updatePreferences(Map<String, bool> newPreferences) async {
    _preferences.addAll(newPreferences);
    await _savePreferences();
    await _updateSubscriptions();
    notifyListeners();
  }

  // Add a new notification to the history
  Future<void> addNotification(NotificationData notification) async {
    _notifications.insert(0, notification);
    
    // Limit history to 100 notifications
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
    
    if (!notification.isRead) {
      _unreadCount++;
    }
    
    await _saveNotificationHistory();
    notifyListeners();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = NotificationData(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        data: _notifications[index].data,
        timestamp: _notifications[index].timestamp,
        isRead: true,
      );
      
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      await _saveNotificationHistory();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool hasChanges = false;
    
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = NotificationData(
          id: _notifications[i].id,
          title: _notifications[i].title,
          body: _notifications[i].body,
          type: _notifications[i].type,
          data: _notifications[i].data,
          timestamp: _notifications[i].timestamp,
          isRead: true,
        );
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _unreadCount = 0;
      await _saveNotificationHistory();
      notifyListeners();
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      if (!_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      _notifications.removeAt(index);
      await _saveNotificationHistory();
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _unreadCount = 0;
    await _saveNotificationHistory();
    notifyListeners();
  }

  // Get notifications by type
  List<NotificationData> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<NotificationData> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Refresh notifications (for pull-to-refresh)
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, you might fetch notifications from a server here
      // For now, we'll just refresh the local data
      await _loadNotificationHistory();
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a test notification (for development/testing)
  Future<void> sendTestNotification() async {
    final testNotification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Test Notification',
      body: 'This is a test notification from Community Beat',
      type: NotificationType.general,
      data: {'test': 'true'},
      timestamp: DateTime.now(),
    );
    
    await addNotification(testNotification);
  }

  // Get notification categories with their display names
  Map<String, String> getNotificationCategories() {
    return {
      'events': 'Community Events',
      'alerts': 'Emergency Alerts',
      'business': 'Business Updates',
      'services': 'Public Services',
      'traffic': 'Traffic Updates',
      'weather': 'Weather Alerts',
      'posts': 'Community Posts',
      'service_requests': 'Service Requests',
    };
  }

  // Check if a category is enabled
  bool isCategoryEnabled(String category) {
    return _preferences[category] ?? false;
  }

  // Get statistics about notifications
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{};
    
    for (final notification in _notifications) {
      final typeKey = notification.type.toString().split('.').last;
      stats[typeKey] = (stats[typeKey] ?? 0) + 1;
    }
    
    return stats;
  }
}