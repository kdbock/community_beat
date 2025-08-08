// lib/utils/constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Community Beat';
  static const String appVersion = '1.0.0';
  
  // Navigation
  static const int newsEventsIndex = 0;
  static const int businessDirectoryIndex = 1;
  static const int bulletinBoardIndex = 2;
  static const int publicServicesIndex = 3;
  static const int mapIndex = 4;
  
  // API Endpoints (placeholder - replace with actual endpoints)
  static const String baseUrl = 'https://api.communitybeat.local';
  static const String eventsEndpoint = '/events';
  static const String businessesEndpoint = '/businesses';
  static const String postsEndpoint = '/posts';
  static const String servicesEndpoint = '/services';
  
  // Categories
  static const List<String> businessCategories = [
    'All',
    'Restaurants',
    'Shopping',
    'Services',
    'Healthcare',
    'Entertainment',
    'Automotive',
    'Real Estate',
    'Education',
    'Other'
  ];
  
  static const List<String> bulletinCategories = [
    'All',
    'Buy/Sell',
    'Jobs',
    'Housing',
    'Lost & Found',
    'Volunteer',
    'Services',
    'Events',
    'Other'
  ];
  
  static const List<String> serviceCategories = [
    'All',
    'Utilities',
    'Public Safety',
    'Transportation',
    'Parks & Recreation',
    'Government',
    'Emergency Services',
    'Other'
  ];
  
  // Shared Preferences Keys
  static const String userPrefsKey = 'user_preferences';
  static const String notificationSettingsKey = 'notification_settings';
  static const String themePreferenceKey = 'theme_preference';
  
  // Default Values
  static const int defaultPageSize = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  
  // Emergency Contacts (example data)
  static const Map<String, String> emergencyContacts = {
    'Police': '911',
    'Fire Department': '911',
    'Medical Emergency': '911',
    'Non-Emergency Police': '(555) 123-4567',
    'City Hall': '(555) 123-4568',
    'Public Works': '(555) 123-4569',
  };
}