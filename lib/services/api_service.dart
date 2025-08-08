// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../models/business.dart';
import '../models/post.dart';

class ApiService {
  static const String _baseUrl = 'https://api.communitybeat.app/v1';
  static const Duration _timeout = Duration(seconds: 30);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client with timeout
  final http.Client _client = http.Client();

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add authentication headers when implemented
    // 'Authorization': 'Bearer $token',
  };

  // Generic GET request
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Handle HTTP responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw ApiException('Bad request: ${response.body}');
      case 401:
        throw ApiException('Unauthorized access');
      case 403:
        throw ApiException('Forbidden access');
      case 404:
        throw ApiException('Resource not found');
      case 500:
        throw ApiException('Server error');
      default:
        throw ApiException('Unexpected error: ${response.statusCode}');
    }
  }

  // Events API
  Future<List<Event>> getEvents({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint = '/events';
    List<String> queryParams = [];

    if (category != null) queryParams.add('category=$category');
    if (startDate != null) queryParams.add('start_date=${startDate.toIso8601String()}');
    if (endDate != null) queryParams.add('end_date=${endDate.toIso8601String()}');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _get(endpoint);
    final List<dynamic> eventsJson = response['data'] ?? [];
    
    return eventsJson.map((json) => Event.fromJson(json)).toList();
  }

  Future<Event> getEvent(String id) async {
    final response = await _get('/events/$id');
    return Event.fromJson(response['data']);
  }

  Future<Event> createEvent(Event event) async {
    final response = await _post('/events', event.toJson());
    return Event.fromJson(response['data']);
  }

  // Businesses API
  Future<List<Business>> getBusinesses({
    String? category,
    String? searchQuery,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    String endpoint = '/businesses';
    List<String> queryParams = [];

    if (category != null) queryParams.add('category=$category');
    if (searchQuery != null) queryParams.add('search=$searchQuery');
    if (latitude != null) queryParams.add('lat=$latitude');
    if (longitude != null) queryParams.add('lng=$longitude');
    if (radius != null) queryParams.add('radius=$radius');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _get(endpoint);
    final List<dynamic> businessesJson = response['data'] ?? [];
    
    return businessesJson.map((json) => Business.fromJson(json)).toList();
  }

  Future<Business> getBusiness(String id) async {
    final response = await _get('/businesses/$id');
    return Business.fromJson(response['data']);
  }

  // Posts API
  Future<List<Post>> getPosts({
    String? category,
    String? type,
    String? searchQuery,
  }) async {
    String endpoint = '/posts';
    List<String> queryParams = [];

    if (category != null) queryParams.add('category=$category');
    if (type != null) queryParams.add('type=$type');
    if (searchQuery != null) queryParams.add('search=$searchQuery');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _get(endpoint);
    final List<dynamic> postsJson = response['data'] ?? [];
    
    return postsJson.map((json) => Post.fromJson(json)).toList();
  }

  Future<Post> getPost(String id) async {
    final response = await _get('/posts/$id');
    return Post.fromJson(response['data']);
  }

  Future<Post> createPost(Post post) async {
    final response = await _post('/posts', post.toJson());
    return Post.fromJson(response['data']);
  }

  // Service Requests API
  Future<Map<String, dynamic>> submitServiceRequest({
    required String title,
    required String description,
    required String category,
    String? location,
    List<String>? imageUrls,
  }) async {
    final data = {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'image_urls': imageUrls,
    };

    return await _post('/service-requests', data);
  }

  Future<List<Map<String, dynamic>>> getServiceRequests() async {
    final response = await _get('/service-requests');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  // Emergency Alerts API
  Future<List<Map<String, dynamic>>> getEmergencyAlerts() async {
    final response = await _get('/alerts');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  // Cleanup
  void dispose() {
    _client.close();
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

// Mock API service for development/testing
class MockApiService {
  Future<List<Event>> getEvents({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock data
    return [
      Event(
        id: '1',
        title: 'Town Hall Meeting',
        description: 'Monthly community meeting to discuss local issues.',
        startDate: DateTime.now().add(const Duration(days: 3)),
        location: 'City Hall',
        category: 'Government',
        organizer: 'City Council',
      ),
      Event(
        id: '2',
        title: 'Summer Festival',
        description: 'Annual summer festival with music and food.',
        startDate: DateTime.now().add(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 17)),
        location: 'Central Park',
        category: 'Entertainment',
        organizer: 'Parks Department',
      ),
    ];
  }

  Future<List<Business>> getBusinesses({
    String? category,
    String? searchQuery,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      Business(
        id: '1',
        name: 'Joe\'s Pizza',
        description: 'Best pizza in town!',
        category: 'Restaurant',
        address: '123 Main St',
        phone: '(555) 123-4567',
        rating: 4.5,
        reviewCount: 127,
        isVerified: true,
      ),
      Business(
        id: '2',
        name: 'Smith Auto Repair',
        description: 'Professional auto repair services.',
        category: 'Automotive',
        address: '456 Oak Ave',
        phone: '(555) 987-6543',
        rating: 4.8,
        reviewCount: 89,
        isVerified: true,
      ),
    ];
  }

  Future<List<Post>> getPosts({
    String? category,
    String? type,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      Post(
        id: '1',
        title: 'iPhone for Sale',
        description: 'Excellent condition iPhone 12.',
        type: PostType.buySell,
        category: 'Electronics',
        authorName: 'John Doe',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        price: 450.0,
      ),
      Post(
        id: '2',
        title: 'Lost Cat',
        description: 'Orange tabby, very friendly.',
        type: PostType.lostFound,
        category: 'Pets',
        authorName: 'Jane Smith',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }
}