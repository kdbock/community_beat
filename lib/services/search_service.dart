// lib/services/search_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/event.dart';
import '../models/business.dart';
import '../models/service_request.dart';

class SearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Comprehensive search across all content types
  static Future<SearchResults> searchAll({
    required String query,
    List<SearchFilter>? filters,
    SearchSortBy sortBy = SearchSortBy.relevance,
    int limit = 50,
  }) async {
    try {
      final results = await Future.wait([
        searchPosts(query: query, filters: filters, limit: limit ~/ 4),
        searchEvents(query: query, filters: filters, limit: limit ~/ 4),
        searchBusinesses(query: query, filters: filters, limit: limit ~/ 4),
        searchServiceRequests(query: query, filters: filters, limit: limit ~/ 4),
      ]);

      return SearchResults(
        posts: results[0] as List<Post>,
        events: results[1] as List<Event>,
        businesses: results[2] as List<Business>,
        serviceRequests: results[3] as List<ServiceRequest>,
        query: query,
        totalResults: (results[0] as List).length +
            (results[1] as List).length +
            (results[2] as List).length +
            (results[3] as List).length,
      );
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }

  /// Search posts with advanced filtering
  static Future<List<Post>> searchPosts({
    required String query,
    List<SearchFilter>? filters,
    PostType? type,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? location,
    int limit = 50,
  }) async {
    try {
      Query queryRef = _firestore.collection('posts');

      // Apply filters
      if (type != null) {
        queryRef = queryRef.where('type', isEqualTo: type.name);
      }

      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      if (dateFrom != null) {
        queryRef = queryRef.where('created_at', isGreaterThanOrEqualTo: dateFrom);
      }

      if (dateTo != null) {
        queryRef = queryRef.where('created_at', isLessThanOrEqualTo: dateTo);
      }

      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      // Apply additional filters
      if (filters != null) {
        for (final filter in filters) {
          queryRef = _applyFilter(queryRef, filter);
        }
      }

      queryRef = queryRef.orderBy('created_at', descending: true).limit(limit);

      final snapshot = await queryRef.get();
      final posts = snapshot.docs
          .map((doc) => Post.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // Filter by text query (client-side for better search)
      if (query.isNotEmpty) {
        return posts.where((post) => _matchesQuery(post, query)).toList();
      }

      return posts;
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  /// Search events with advanced filtering
  static Future<List<Event>> searchEvents({
    required String query,
    List<SearchFilter>? filters,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? location,
    bool upcomingOnly = false,
    int limit = 50,
  }) async {
    try {
      Query queryRef = _firestore.collection('events');

      // Apply filters
      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      if (upcomingOnly) {
        queryRef = queryRef.where('start_date', isGreaterThan: DateTime.now());
      }

      if (dateFrom != null) {
        queryRef = queryRef.where('start_date', isGreaterThanOrEqualTo: dateFrom);
      }

      if (dateTo != null) {
        queryRef = queryRef.where('start_date', isLessThanOrEqualTo: dateTo);
      }

      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location_name', isEqualTo: location);
      }

      // Apply additional filters
      if (filters != null) {
        for (final filter in filters) {
          queryRef = _applyFilter(queryRef, filter);
        }
      }

      queryRef = queryRef.orderBy('start_date', descending: false).limit(limit);

      final snapshot = await queryRef.get();
      final events = snapshot.docs
          .map((doc) => Event.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // Filter by text query (client-side for better search)
      if (query.isNotEmpty) {
        return events.where((event) => _matchesQuery(event, query)).toList();
      }

      return events;
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  /// Search businesses with advanced filtering
  static Future<List<Business>> searchBusinesses({
    required String query,
    List<SearchFilter>? filters,
    String? category,
    String? location,
    bool verifiedOnly = false,
    double? maxDistance,
    int limit = 50,
  }) async {
    try {
      Query queryRef = _firestore.collection('businesses');

      // Apply filters
      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      if (verifiedOnly) {
        queryRef = queryRef.where('is_verified', isEqualTo: true);
      }

      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('address', isEqualTo: location);
      }

      // Apply additional filters
      if (filters != null) {
        for (final filter in filters) {
          queryRef = _applyFilter(queryRef, filter);
        }
      }

      queryRef = queryRef.limit(limit);

      final snapshot = await queryRef.get();
      final businesses = snapshot.docs
          .map((doc) => Business.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // Filter by text query (client-side for better search)
      if (query.isNotEmpty) {
        return businesses.where((business) => _matchesQuery(business, query)).toList();
      }

      return businesses;
    } catch (e) {
      throw Exception('Failed to search businesses: $e');
    }
  }

  /// Search service requests with advanced filtering
  static Future<List<ServiceRequest>> searchServiceRequests({
    required String query,
    List<SearchFilter>? filters,
    String? category,
    ServiceRequestStatus? status,
    ServiceRequestPriority? priority,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 50,
  }) async {
    try {
      Query queryRef = _firestore.collection('service_requests');

      // Apply filters
      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      if (status != null) {
        queryRef = queryRef.where('status', isEqualTo: status.name);
      }

      if (priority != null) {
        queryRef = queryRef.where('priority', isEqualTo: priority.name);
      }

      if (dateFrom != null) {
        queryRef = queryRef.where('created_at', isGreaterThanOrEqualTo: dateFrom);
      }

      if (dateTo != null) {
        queryRef = queryRef.where('created_at', isLessThanOrEqualTo: dateTo);
      }

      // Apply additional filters
      if (filters != null) {
        for (final filter in filters) {
          queryRef = _applyFilter(queryRef, filter);
        }
      }

      queryRef = queryRef.orderBy('created_at', descending: true).limit(limit);

      final snapshot = await queryRef.get();
      final serviceRequests = snapshot.docs
          .map((doc) => ServiceRequest.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // Filter by text query (client-side for better search)
      if (query.isNotEmpty) {
        return serviceRequests.where((request) => _matchesQuery(request, query)).toList();
      }

      return serviceRequests;
    } catch (e) {
      throw Exception('Failed to search service requests: $e');
    }
  }

  /// Get search suggestions based on query
  static Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      final suggestions = <String>{};
      
      // Get suggestions from posts
      final postsSnapshot = await _firestore
          .collection('posts')
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(10)
          .get();
      
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        suggestions.add(data['title'] ?? '');
        if (data['tags'] != null) {
          for (final tag in data['tags'] as List) {
            if (tag.toString().toLowerCase().contains(query.toLowerCase())) {
              suggestions.add(tag.toString());
            }
          }
        }
      }

      // Get suggestions from events
      final eventsSnapshot = await _firestore
          .collection('events')
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(10)
          .get();
      
      for (final doc in eventsSnapshot.docs) {
        final data = doc.data();
        suggestions.add(data['title'] ?? '');
      }

      // Get suggestions from businesses
      final businessesSnapshot = await _firestore
          .collection('businesses')
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(10)
          .get();
      
      for (final doc in businessesSnapshot.docs) {
        final data = doc.data();
        suggestions.add(data['name'] ?? '');
      }

      return suggestions.where((s) => s.isNotEmpty).take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get popular search terms
  static Future<List<String>> getPopularSearchTerms() async {
    try {
      // In a real app, you'd track search analytics
      // For now, return some common terms
      return [
        'events',
        'business',
        'services',
        'housing',
        'jobs',
        'volunteer',
        'community',
        'local',
        'help',
        'support',
      ];
    } catch (e) {
      return [];
    }
  }

  /// Save search query for analytics
  static Future<void> saveSearchQuery(String query, String userId) async {
    try {
      await _firestore.collection('search_analytics').add({
        'query': query,
        'user_id': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - analytics are not critical
    }
  }

  /// Apply a search filter to a query
  static Query _applyFilter(Query query, SearchFilter filter) {
    switch (filter.type) {
      case SearchFilterType.equals:
        return query.where(filter.field, isEqualTo: filter.value);
      case SearchFilterType.contains:
        return query.where(filter.field, arrayContains: filter.value);
      case SearchFilterType.greaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case SearchFilterType.lessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case SearchFilterType.greaterThanOrEqual:
        return query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
      case SearchFilterType.lessThanOrEqual:
        return query.where(filter.field, isLessThanOrEqualTo: filter.value);
      case SearchFilterType.arrayContainsAny:
        return query.where(filter.field, arrayContainsAny: filter.value as List);
      case SearchFilterType.whereIn:
        return query.where(filter.field, whereIn: filter.value as List);
    }
  }

  /// Check if an object matches the search query
  static bool _matchesQuery(dynamic object, String query) {
    final searchTerms = query.toLowerCase().split(' ');
    final searchableText = _getSearchableText(object).toLowerCase();
    
    return searchTerms.every((term) => searchableText.contains(term));
  }

  /// Extract searchable text from an object
  static String _getSearchableText(dynamic object) {
    if (object is Post) {
      return '${object.title} ${object.description} ${object.category} ${object.authorName} ${object.tags.join(' ')}';
    } else if (object is Event) {
      return '${object.title} ${object.description} ${object.category} ${object.organizer} ${object.location} ${object.tags.join(' ')}';
    } else if (object is Business) {
      return '${object.name} ${object.description} ${object.category} ${object.address}';
    } else if (object is ServiceRequest) {
      return '${object.title} ${object.description} ${object.category} ${object.tags.join(' ')}';
    }
    return '';
  }
}

/// Search results container
class SearchResults {
  final List<Post> posts;
  final List<Event> events;
  final List<Business> businesses;
  final List<ServiceRequest> serviceRequests;
  final String query;
  final int totalResults;

  SearchResults({
    required this.posts,
    required this.events,
    required this.businesses,
    required this.serviceRequests,
    required this.query,
    required this.totalResults,
  });

  bool get isEmpty => totalResults == 0;
  bool get isNotEmpty => totalResults > 0;

  List<dynamic> get allResults => [
    ...posts,
    ...events,
    ...businesses,
    ...serviceRequests,
  ];
}

/// Search filter for advanced filtering
class SearchFilter {
  final String field;
  final SearchFilterType type;
  final dynamic value;

  SearchFilter({
    required this.field,
    required this.type,
    required this.value,
  });
}

/// Search filter types
enum SearchFilterType {
  equals,
  contains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  arrayContainsAny,
  whereIn,
}

/// Search sort options
enum SearchSortBy {
  relevance,
  date,
  alphabetical,
  distance,
  popularity,
}