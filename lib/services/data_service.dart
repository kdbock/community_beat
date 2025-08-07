// lib/services/data_service.dart

import '../models/event.dart';
import '../models/business.dart';
import '../models/post.dart';
import '../models/service_request.dart';
import 'firestore_service.dart';

/// Unified data service that provides a clean interface for data operations
/// This service uses Firestore as the backend but could be easily switched
/// to use other backends by changing the implementation
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // POSTS OPERATIONS

  /// Create a new post
  Future<Post> createPost(Post post) async {
    return await _firestoreService.createPost(post);
  }

  /// Get all posts with optional filtering
  Future<List<Post>> getPosts({
    String? category,
    PostType? type,
    String? searchQuery,
    int? limit = 50,
  }) async {
    return await _firestoreService.getPosts(
      category: category,
      type: type,
      searchQuery: searchQuery,
      limit: limit,
    );
  }

  /// Get a single post by ID
  Future<Post> getPost(String id) async {
    return await _firestoreService.getPost(id);
  }

  /// Update a post
  Future<Post> updatePost(Post post) async {
    return await _firestoreService.updatePost(post);
  }

  /// Delete a post
  Future<void> deletePost(String id) async {
    await _firestoreService.deletePost(id);
  }

  /// Increment post view count
  Future<void> incrementPostViewCount(String id) async {
    await _firestoreService.incrementPostViewCount(id);
  }

  /// Listen to posts changes in real-time
  Stream<List<Post>> listenToPosts({
    String? category,
    PostType? type,
    int? limit = 50,
  }) {
    return _firestoreService.listenToPosts(
      category: category,
      type: type,
      limit: limit,
    );
  }

  // BUSINESSES OPERATIONS

  /// Create a new business
  Future<Business> createBusiness(Business business) async {
    return await _firestoreService.createBusiness(business);
  }

  /// Get all businesses with optional filtering
  Future<List<Business>> getBusinesses({
    String? category,
    String? searchQuery,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? limit = 50,
  }) async {
    return await _firestoreService.getBusinesses(
      category: category,
      searchQuery: searchQuery,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
    );
  }

  /// Get a single business by ID
  Future<Business> getBusiness(String id) async {
    return await _firestoreService.getBusiness(id);
  }

  /// Update a business
  Future<Business> updateBusiness(Business business) async {
    return await _firestoreService.updateBusiness(business);
  }

  /// Delete a business
  Future<void> deleteBusiness(String id) async {
    await _firestoreService.deleteBusiness(id);
  }

  /// Listen to businesses changes in real-time
  Stream<List<Business>> listenToBusinesses({
    String? category,
    int? limit = 50,
  }) {
    return _firestoreService.listenToBusinesses(
      category: category,
      limit: limit,
    );
  }

  // EVENTS OPERATIONS

  /// Create a new event
  Future<Event> createEvent(Event event) async {
    return await _firestoreService.createEvent(event);
  }

  /// Get all events with optional filtering
  Future<List<Event>> getEvents({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool? upcomingOnly = true,
    int? limit = 50,
  }) async {
    return await _firestoreService.getEvents(
      category: category,
      startDate: startDate,
      endDate: endDate,
      upcomingOnly: upcomingOnly,
      limit: limit,
    );
  }

  /// Get a single event by ID
  Future<Event> getEvent(String id) async {
    return await _firestoreService.getEvent(id);
  }

  /// Update an event
  Future<Event> updateEvent(Event event) async {
    return await _firestoreService.updateEvent(event);
  }

  /// Delete an event
  Future<void> deleteEvent(String id) async {
    await _firestoreService.deleteEvent(id);
  }

  /// Listen to events changes in real-time
  Stream<List<Event>> listenToEvents({
    String? category,
    bool? upcomingOnly = true,
    int? limit = 50,
  }) {
    return _firestoreService.listenToEvents(
      category: category,
      upcomingOnly: upcomingOnly,
      limit: limit,
    );
  }

  // SERVICE REQUESTS OPERATIONS

  /// Submit a service request
  Future<ServiceRequest> submitServiceRequest({
    required String title,
    required String description,
    required String category,
    String? location,
    List<String>? imageUrls,
    String? contactInfo,
  }) async {
    // Create a ServiceRequest object
    final serviceRequest = ServiceRequest(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      category: category,
      priority: ServiceRequestPriority.medium,
      status: ServiceRequestStatus.open,
      requesterId: '', // Should be set based on current user
      requesterName: '', // Should be set based on current user
      location: location,
      imageUrls: imageUrls ?? [],
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isUrgent: false,
      upvoteCount: 0,
      upvotedBy: [],
    );
    
    return await _firestoreService.createServiceRequest(serviceRequest);
  }

  /// Get service requests
  Future<List<ServiceRequest>> getServiceRequests({
    ServiceRequestStatus? status,
    String? category,
    int? limit = 50,
  }) async {
    return await _firestoreService.getServiceRequests(
      status: status,
      category: category,
      limit: limit,
    );
  }

  // EMERGENCY ALERTS OPERATIONS

  /// Get emergency alerts
  Future<List<Map<String, dynamic>>> getEmergencyAlerts({
    bool? activeOnly = true,
    int? limit = 10,
  }) async {
    return await _firestoreService.getEmergencyAlerts(
      activeOnly: activeOnly,
      limit: limit,
    );
  }

  /// Create an emergency alert (admin function)
  Future<String> createEmergencyAlert({
    required String title,
    required String message,
    required String severity,
    String? category,
    DateTime? expiresAt,
  }) async {
    return await _firestoreService.createEmergencyAlert(
      title: title,
      message: message,
      severity: severity,
      category: category,
      expiresAt: expiresAt,
    );
  }

  // UTILITY METHODS

  /// Get popular categories for posts
  Future<List<String>> getPopularPostCategories() async {
    // This could be implemented with Firestore aggregation queries
    // For now, return common categories
    return [
      'Electronics',
      'Furniture',
      'Vehicles',
      'Jobs',
      'Housing',
      'Services',
      'Pets',
      'Community',
    ];
  }

  /// Get popular business categories
  Future<List<String>> getPopularBusinessCategories() async {
    return [
      'Restaurant',
      'Retail',
      'Healthcare',
      'Automotive',
      'Beauty & Wellness',
      'Professional Services',
      'Home & Garden',
      'Entertainment',
    ];
  }

  /// Get popular event categories
  Future<List<String>> getPopularEventCategories() async {
    return [
      'Community',
      'Entertainment',
      'Education',
      'Sports',
      'Arts & Culture',
      'Government',
      'Health & Wellness',
      'Business',
    ];
  }

  // SEARCH OPERATIONS

  /// Perform a global search across all content types
  Future<Map<String, List<dynamic>>> globalSearch(String query) async {
    if (query.trim().isEmpty) {
      return {
        'posts': <Post>[],
        'businesses': <Business>[],
        'events': <Event>[],
      };
    }

    // Perform parallel searches
    final results = await Future.wait([
      getPosts(searchQuery: query, limit: 10),
      getBusinesses(searchQuery: query, limit: 10),
      getEvents(upcomingOnly: true, limit: 10),
    ]);

    // Filter events by search query (since Firestore doesn't support full-text search natively)
    final events = (results[2] as List<Event>).where((event) =>
      event.title.toLowerCase().contains(query.toLowerCase()) ||
      event.description.toLowerCase().contains(query.toLowerCase()) ||
      event.category.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return {
      'posts': results[0] as List<Post>,
      'businesses': results[1] as List<Business>,
      'events': events,
    };
  }

  // STATISTICS OPERATIONS

  /// Get dashboard statistics
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final results = await Future.wait([
        getPosts(limit: 1000), // Get all posts to count
        getBusinesses(limit: 1000), // Get all businesses to count
        getEvents(upcomingOnly: true, limit: 1000), // Get upcoming events to count
        getServiceRequests(status: ServiceRequestStatus.open, limit: 1000), // Get open service requests
      ]);

      return {
        'total_posts': (results[0] as List<Post>).length,
        'total_businesses': (results[1] as List<Business>).length,
        'upcoming_events': (results[2] as List<Event>).length,
        'pending_service_requests': (results[3] as List<Map<String, dynamic>>).length,
      };
    } catch (e) {
      // Return default values if there's an error
      return {
        'total_posts': 0,
        'total_businesses': 0,
        'upcoming_events': 0,
        'pending_service_requests': 0,
      };
    }
  }
}