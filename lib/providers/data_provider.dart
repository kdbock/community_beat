// lib/providers/data_provider.dart

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/business.dart';
import '../models/post.dart';
import '../services/data_service.dart';
import '../services/data_seeder.dart';

/// Main data provider that manages all data operations using Firestore
class DataProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  final DataSeeder _dataSeeder = DataSeeder();

  // Loading states
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Data
  List<Post> _posts = [];
  List<Business> _businesses = [];
  List<Event> _events = [];
  List<Map<String, dynamic>> _serviceRequests = [];
  List<Map<String, dynamic>> _emergencyAlerts = [];
  Map<String, int> _dashboardStats = {};

  // Filters
  String? _selectedPostCategory;
  PostType? _selectedPostType;
  String? _selectedBusinessCategory;
  String? _selectedEventCategory;
  String _searchQuery = '';

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  List<Post> get posts => _filteredPosts;
  List<Business> get businesses => _filteredBusinesses;
  List<Event> get events => _filteredEvents;
  List<Map<String, dynamic>> get serviceRequests => _serviceRequests;
  List<Map<String, dynamic>> get emergencyAlerts => _emergencyAlerts;
  Map<String, int> get dashboardStats => _dashboardStats;

  String? get selectedPostCategory => _selectedPostCategory;
  PostType? get selectedPostType => _selectedPostType;
  String? get selectedBusinessCategory => _selectedBusinessCategory;
  String? get selectedEventCategory => _selectedEventCategory;
  String get searchQuery => _searchQuery;

  // Filtered data
  List<Post> get _filteredPosts {
    var filtered = _posts;

    if (_selectedPostCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedPostCategory).toList();
    }

    if (_selectedPostType != null) {
      filtered = filtered.where((p) => p.type == _selectedPostType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  List<Business> get _filteredBusinesses {
    var filtered = _businesses;

    if (_selectedBusinessCategory != null) {
      filtered = filtered.where((b) => b.category == _selectedBusinessCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) =>
        b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        b.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        b.services.any((service) => 
          service.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    return filtered;
  }

  List<Event> get _filteredEvents {
    var filtered = _events;

    if (_selectedEventCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedEventCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) =>
        e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  // Initialization
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      // Seed data if database is empty
      await _dataSeeder.seedIfEmpty();
      
      // Load initial data
      await Future.wait([
        loadPosts(),
        loadBusinesses(),
        loadEvents(),
        loadServiceRequests(),
        loadEmergencyAlerts(),
        loadDashboardStats(),
      ]);

      _isInitialized = true;
      _clearError();
    } catch (e) {
      _setError('Failed to initialize data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // POSTS OPERATIONS

  Future<void> loadPosts({bool refresh = false}) async {
    if (!refresh && _posts.isNotEmpty) return;

    try {
      _posts = await _dataService.getPosts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load posts: $e');
    }
  }

  Future<Post?> createPost(Post post) async {
    _setLoading(true);
    try {
      final createdPost = await _dataService.createPost(post);
      _posts.insert(0, createdPost);
      _clearError();
      notifyListeners();
      return createdPost;
    } catch (e) {
      _setError('Failed to create post: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePost(Post post) async {
    _setLoading(true);
    try {
      final updatedPost = await _dataService.updatePost(post);
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update post: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _dataService.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete post: $e');
      return false;
    }
  }

  Future<void> incrementPostViewCount(String postId) async {
    try {
      await _dataService.incrementPostViewCount(postId);
      // Update local data
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          viewCount: _posts[index].viewCount + 1
        );
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for view count increment
      debugPrint('Failed to increment view count: $e');
    }
  }

  // BUSINESSES OPERATIONS

  Future<void> loadBusinesses({bool refresh = false}) async {
    if (!refresh && _businesses.isNotEmpty) return;

    try {
      _businesses = await _dataService.getBusinesses();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load businesses: $e');
    }
  }

  Future<Business?> createBusiness(Business business) async {
    _setLoading(true);
    try {
      final createdBusiness = await _dataService.createBusiness(business);
      _businesses.insert(0, createdBusiness);
      _clearError();
      notifyListeners();
      return createdBusiness;
    } catch (e) {
      _setError('Failed to create business: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBusiness(Business business) async {
    _setLoading(true);
    try {
      final updatedBusiness = await _dataService.updateBusiness(business);
      final index = _businesses.indexWhere((b) => b.id == business.id);
      if (index != -1) {
        _businesses[index] = updatedBusiness;
      }
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update business: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBusiness(String businessId) async {
    try {
      await _dataService.deleteBusiness(businessId);
      _businesses.removeWhere((b) => b.id == businessId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete business: $e');
      return false;
    }
  }

  // EVENTS OPERATIONS

  Future<void> loadEvents({bool refresh = false}) async {
    if (!refresh && _events.isNotEmpty) return;

    try {
      _events = await _dataService.getEvents();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load events: $e');
    }
  }

  Future<Event?> createEvent(Event event) async {
    _setLoading(true);
    try {
      final createdEvent = await _dataService.createEvent(event);
      _events.insert(0, createdEvent);
      _clearError();
      notifyListeners();
      return createdEvent;
    } catch (e) {
      _setError('Failed to create event: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateEvent(Event event) async {
    _setLoading(true);
    try {
      final updatedEvent = await _dataService.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = updatedEvent;
      }
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update event: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _dataService.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete event: $e');
      return false;
    }
  }

  // SERVICE REQUESTS OPERATIONS

  Future<void> loadServiceRequests({bool refresh = false}) async {
    if (!refresh && _serviceRequests.isNotEmpty) return;

    try {
      _serviceRequests = await _dataService.getServiceRequests();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load service requests: $e');
    }
  }

  Future<String?> submitServiceRequest({
    required String title,
    required String description,
    required String category,
    String? location,
    List<String>? imageUrls,
    String? contactInfo,
  }) async {
    _setLoading(true);
    try {
      final requestId = await _dataService.submitServiceRequest(
        title: title,
        description: description,
        category: category,
        location: location,
        imageUrls: imageUrls,
        contactInfo: contactInfo,
      );
      
      // Refresh service requests
      await loadServiceRequests(refresh: true);
      
      _clearError();
      return requestId;
    } catch (e) {
      _setError('Failed to submit service request: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // EMERGENCY ALERTS OPERATIONS

  Future<void> loadEmergencyAlerts({bool refresh = false}) async {
    if (!refresh && _emergencyAlerts.isNotEmpty) return;

    try {
      _emergencyAlerts = await _dataService.getEmergencyAlerts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load emergency alerts: $e');
    }
  }

  Future<String?> createEmergencyAlert({
    required String title,
    required String message,
    required String severity,
    String? category,
    DateTime? expiresAt,
  }) async {
    _setLoading(true);
    try {
      final alertId = await _dataService.createEmergencyAlert(
        title: title,
        message: message,
        severity: severity,
        category: category,
        expiresAt: expiresAt,
      );
      
      // Refresh alerts
      await loadEmergencyAlerts(refresh: true);
      
      _clearError();
      return alertId;
    } catch (e) {
      _setError('Failed to create emergency alert: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // DASHBOARD STATS

  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _dataService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load dashboard stats: $e');
    }
  }

  // SEARCH OPERATIONS

  Future<Map<String, List<dynamic>>> globalSearch(String query) async {
    try {
      return await _dataService.globalSearch(query);
    } catch (e) {
      _setError('Search failed: $e');
      return {
        'posts': <Post>[],
        'businesses': <Business>[],
        'events': <Event>[],
      };
    }
  }

  // FILTER OPERATIONS

  void setPostCategory(String? category) {
    _selectedPostCategory = category;
    notifyListeners();
  }

  void setPostType(PostType? type) {
    _selectedPostType = type;
    notifyListeners();
  }

  void setBusinessCategory(String? category) {
    _selectedBusinessCategory = category;
    notifyListeners();
  }

  void setEventCategory(String? category) {
    _selectedEventCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedPostCategory = null;
    _selectedPostType = null;
    _selectedBusinessCategory = null;
    _selectedEventCategory = null;
    _searchQuery = '';
    notifyListeners();
  }

  // CATEGORY HELPERS

  Future<List<String>> getPostCategories() async {
    return await _dataService.getPopularPostCategories();
  }

  Future<List<String>> getBusinessCategories() async {
    return await _dataService.getPopularBusinessCategories();
  }

  Future<List<String>> getEventCategories() async {
    return await _dataService.getPopularEventCategories();
  }

  // UTILITY METHODS

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // REFRESH ALL DATA

  Future<void> refreshAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadPosts(refresh: true),
        loadBusinesses(refresh: true),
        loadEvents(refresh: true),
        loadServiceRequests(refresh: true),
        loadEmergencyAlerts(refresh: true),
        loadDashboardStats(),
      ]);
      _clearError();
    } catch (e) {
      _setError('Failed to refresh data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // REAL-TIME LISTENERS (for future implementation)

  Stream<List<Post>> get postsStream => _dataService.listenToPosts();
  Stream<List<Business>> get businessesStream => _dataService.listenToBusinesses();
  Stream<List<Event>> get eventsStream => _dataService.listenToEvents();

  // CLEANUP

  @override
  void dispose() {
    super.dispose();
  }
}