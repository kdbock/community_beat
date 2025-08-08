// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/event.dart';
import '../models/business.dart';
import '../models/post.dart';
import '../models/user_model.dart';
import '../models/service_request.dart';

class FirestoreService {
  /// Public method to get user profile by UID (for provider compatibility)
  Future<UserModel?> getUserProfile(String uid) async {
    return await FirestoreServiceExtensions(this).getUserProfile(uid);
  }

  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _businessesCollection =>
      _firestore.collection('businesses');
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _serviceRequestsCollection =>
      _firestore.collection('service_requests');
  CollectionReference get _emergencyAlertsCollection =>
      _firestore.collection('emergency_alerts');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // POSTS CRUD OPERATIONS

  /// Create a new post
  Future<Post> createPost(Post post) async {
    try {
      final docRef = await _postsCollection.add(post.toJson());
      final createdPost = post.copyWith(id: docRef.id);

      // Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      return createdPost;
    } catch (e) {
      throw FirestoreException('Failed to create post: $e');
    }
  }

  /// Get all posts with optional filtering
  Future<List<Post>> getPosts({
    String? category,
    PostType? type,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      Query query = _postsCollection.where('is_active', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      // Order by creation date (newest first)
      query = query.orderBy('created_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      List<Post> posts =
          querySnapshot.docs
              .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

      // Apply search filter if provided (client-side filtering for simplicity)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        posts =
            posts
                .where(
                  (post) =>
                      post.title.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      post.description.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ),
                )
                .toList();
      }

      return posts;
    } catch (e) {
      throw FirestoreException('Failed to get posts: $e');
    }
  }

  /// Get a single post by ID
  Future<Post> getPost(String id) async {
    try {
      final doc = await _postsCollection.doc(id).get();
      if (!doc.exists) {
        throw FirestoreException('Post not found');
      }
      return Post.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException('Failed to get post: $e');
    }
  }

  /// Update a post
  Future<Post> updatePost(Post post) async {
    try {
      await _postsCollection.doc(post.id).update(post.toJson());
      return post;
    } catch (e) {
      throw FirestoreException('Failed to update post: $e');
    }
  }

  /// Delete a post (soft delete by setting is_active to false)
  Future<void> deletePost(String id) async {
    try {
      await _postsCollection.doc(id).update({'is_active': false});
    } catch (e) {
      throw FirestoreException('Failed to delete post: $e');
    }
  }

  /// Increment post view count
  Future<void> incrementPostViewCount(String id) async {
    try {
      await _postsCollection.doc(id).update({
        'view_count': FieldValue.increment(1),
      });
    } catch (e) {
      throw FirestoreException('Failed to increment view count: $e');
    }
  }

  // BUSINESSES CRUD OPERATIONS

  /// Create a new business
  Future<Business> createBusiness(Business business) async {
    try {
      final docRef = await _businessesCollection.add(business.toJson());
      final createdBusiness = business.copyWith(id: docRef.id);

      // Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      return createdBusiness;
    } catch (e) {
      throw FirestoreException('Failed to create business: $e');
    }
  }

  /// Get all businesses with optional filtering
  Future<List<Business>> getBusinesses({
    String? category,
    String? searchQuery,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? limit,
  }) async {
    try {
      Query query = _businessesCollection;

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Order by rating (highest first)
      query = query.orderBy('rating', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      List<Business> businesses =
          querySnapshot.docs
              .map(
                (doc) => Business.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        businesses =
            businesses
                .where(
                  (business) =>
                      business.name.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      business.description.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      business.services.any(
                        (service) => service.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      ),
                )
                .toList();
      }

      // Apply location filter if provided (simple distance calculation)
      if (latitude != null && longitude != null && radiusKm != null) {
        businesses =
            businesses.where((business) {
              if (business.latitude == null || business.longitude == null)
                return false;

              final distance = _calculateDistance(
                latitude,
                longitude,
                business.latitude!,
                business.longitude!,
              );

              return distance <= radiusKm;
            }).toList();
      }

      return businesses;
    } catch (e) {
      throw FirestoreException('Failed to get businesses: $e');
    }
  }

  /// Get a single business by ID
  Future<Business> getBusiness(String id) async {
    try {
      final doc = await _businessesCollection.doc(id).get();
      if (!doc.exists) {
        throw FirestoreException('Business not found');
      }
      return Business.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException('Failed to get business: $e');
    }
  }

  /// Update a business
  Future<Business> updateBusiness(Business business) async {
    try {
      await _businessesCollection.doc(business.id).update(business.toJson());
      return business;
    } catch (e) {
      throw FirestoreException('Failed to update business: $e');
    }
  }

  /// Delete a business
  Future<void> deleteBusiness(String id) async {
    try {
      await _businessesCollection.doc(id).delete();
    } catch (e) {
      throw FirestoreException('Failed to delete business: $e');
    }
  }

  // EVENTS CRUD OPERATIONS

  /// Create a new event
  Future<Event> createEvent(Event event) async {
    try {
      final docRef = await _eventsCollection.add(event.toJson());
      final createdEvent = event.copyWith(id: docRef.id);

      // Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      return createdEvent;
    } catch (e) {
      throw FirestoreException('Failed to create event: $e');
    }
  }

  /// Get all events with optional filtering
  Future<List<Event>> getEvents({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool? upcomingOnly = true,
    int? limit,
  }) async {
    try {
      Query query = _eventsCollection;

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (upcomingOnly == true) {
        query = query.where(
          'start_date',
          isGreaterThanOrEqualTo: DateTime.now().toIso8601String(),
        );
      }

      if (startDate != null) {
        query = query.where(
          'start_date',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        query = query.where(
          'start_date',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      // Order by start date (earliest first)
      query = query.orderBy('start_date');

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Event.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get events: $e');
    }
  }

  /// Get a single event by ID
  Future<Event> getEvent(String id) async {
    try {
      final doc = await _eventsCollection.doc(id).get();
      if (!doc.exists) {
        throw FirestoreException('Event not found');
      }
      return Event.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException('Failed to get event: $e');
    }
  }

  /// Update an event
  Future<Event> updateEvent(Event event) async {
    try {
      await _eventsCollection.doc(event.id).update(event.toJson());
      return event;
    } catch (e) {
      throw FirestoreException('Failed to update event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String id) async {
    try {
      await _eventsCollection.doc(id).delete();
    } catch (e) {
      throw FirestoreException('Failed to delete event: $e');
    }
  }

  // EMERGENCY ALERTS OPERATIONS

  /// Get emergency alerts
  Future<List<Map<String, dynamic>>> getEmergencyAlerts({
    bool? activeOnly = true,
    int? limit,
  }) async {
    try {
      Query query = _emergencyAlertsCollection;

      if (activeOnly == true) {
        query = query.where('is_active', isEqualTo: true);
      }

      query = query.orderBy('created_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get emergency alerts: $e');
    }
  }

  /// Create an emergency alert (admin function)
  Future<String> createEmergencyAlert({
    required String title,
    required String message,
    required String severity, // 'low', 'medium', 'high', 'critical'
    String? category,
    DateTime? expiresAt,
  }) async {
    try {
      final data = {
        'title': title,
        'message': message,
        'severity': severity,
        'category': category,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };

      final docRef = await _emergencyAlertsCollection.add(data);
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw FirestoreException('Failed to create emergency alert: $e');
    }
  }

  // UTILITY METHODS

  /// Calculate distance between two coordinates in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // BATCH OPERATIONS

  /// Batch write operations for better performance
  WriteBatch get batch => _firestore.batch();

  /// Commit a batch operation
  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw FirestoreException('Failed to commit batch operation: $e');
    }
  }

  // REAL-TIME LISTENERS

  /// Listen to posts changes
  Stream<List<Post>> listenToPosts({
    String? category,
    PostType? type,
    int? limit,
  }) {
    Query query = _postsCollection.where('is_active', isEqualTo: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }

    query = query.orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
    );
  }

  /// Listen to events changes
  Stream<List<Event>> listenToEvents({
    String? category,
    bool? upcomingOnly = true,
    int? limit,
  }) {
    Query query = _eventsCollection;

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (upcomingOnly == true) {
      query = query.where(
        'start_date',
        isGreaterThanOrEqualTo: DateTime.now().toIso8601String(),
      );
    }

    query = query.orderBy('start_date');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => Event.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
    );
  }

  /// Listen to businesses changes
  Stream<List<Business>> listenToBusinesses({String? category, int? limit}) {
    Query query = _businessesCollection;

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('rating', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => Business.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

/// Custom exception for Firestore operations
class FirestoreException implements Exception {
  final String message;
  FirestoreException(this.message);

  @override
  String toString() => 'FirestoreException: $message';
}

// Extension to add copyWith method to Business model if not present
extension BusinessCopyWith on Business {
  Business copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? address,
    String? phone,
    String? email,
    String? website,
    Map<String, String>? hours,
    List<String>? imageUrls,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    List<String>? services,
    bool? isVerified,
    bool? isNew,
    double? latitude,
    double? longitude,
    List<Deal>? deals,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      hours: hours ?? this.hours,
      imageUrls: imageUrls ?? this.imageUrls,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      services: services ?? this.services,
      isVerified: isVerified ?? this.isVerified,
      isNew: isNew ?? this.isNew,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deals: deals ?? this.deals,
    );
  }
}

extension FirestoreServiceExtensions on FirestoreService {
  // SERVICE REQUEST CRUD OPERATIONS

  /// Create a new service request
  Future<ServiceRequest> createServiceRequest(
    ServiceRequest serviceRequest,
  ) async {
    try {
      final docRef = await _serviceRequestsCollection.add(
        serviceRequest.toJson(),
      );
      final createdRequest = serviceRequest.copyWith(id: docRef.id);

      // Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      return createdRequest;
    } catch (e) {
      throw FirestoreException('Failed to create service request: $e');
    }
  }

  /// Get all service requests with optional filtering
  Future<List<ServiceRequest>> getServiceRequests({
    String? category,
    ServiceRequestStatus? status,
    ServiceRequestPriority? priority,
    String? searchQuery,
    bool? isUrgent,
    int? limit,
  }) async {
    try {
      Query query = _serviceRequestsCollection;

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (status != null) {
        query = query.where(
          'status',
          isEqualTo: status.toString().split('.').last,
        );
      }

      if (priority != null) {
        query = query.where(
          'priority',
          isEqualTo: priority.toString().split('.').last,
        );
      }

      if (isUrgent != null) {
        query = query.where('is_urgent', isEqualTo: isUrgent);
      }

      query = query.orderBy('created_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      List<ServiceRequest> requests =
          snapshot.docs
              .map(
                (doc) =>
                    ServiceRequest.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        requests =
            requests
                .where(
                  (request) =>
                      request.title.toLowerCase().contains(searchLower) ||
                      request.description.toLowerCase().contains(searchLower) ||
                      request.category.toLowerCase().contains(searchLower) ||
                      request.tags.any(
                        (tag) => tag.toLowerCase().contains(searchLower),
                      ),
                )
                .toList();
      }

      return requests;
    } catch (e) {
      throw FirestoreException('Failed to get service requests: $e');
    }
  }

  /// Get service request by ID
  Future<ServiceRequest?> getServiceRequest(String id) async {
    try {
      final doc = await _serviceRequestsCollection.doc(id).get();
      if (doc.exists) {
        return ServiceRequest.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw FirestoreException('Failed to get service request: $e');
    }
  }

  /// Update service request
  Future<ServiceRequest> updateServiceRequest(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _serviceRequestsCollection.doc(id).update(updates);

      final updatedDoc = await _serviceRequestsCollection.doc(id).get();
      return ServiceRequest.fromJson(updatedDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException('Failed to update service request: $e');
    }
  }

  /// Delete service request
  Future<void> deleteServiceRequest(String id) async {
    try {
      await _serviceRequestsCollection.doc(id).delete();
    } catch (e) {
      throw FirestoreException('Failed to delete service request: $e');
    }
  }

  /// Get service requests by user
  Future<List<ServiceRequest>> getUserServiceRequests(String userId) async {
    try {
      final snapshot =
          await _serviceRequestsCollection
              .where('requester_id', isEqualTo: userId)
              .orderBy('created_at', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get user service requests: $e');
    }
  }

  /// Assign service request to user
  Future<ServiceRequest> assignServiceRequest(
    String requestId,
    String assigneeId,
    String assigneeName,
  ) async {
    try {
      final updates = {
        'assigned_to': assigneeId,
        'assigned_to_name': assigneeName,
        'status': ServiceRequestStatus.inProgress.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      return await updateServiceRequest(requestId, updates);
    } catch (e) {
      throw FirestoreException('Failed to assign service request: $e');
    }
  }

  /// Resolve service request
  Future<ServiceRequest> resolveServiceRequest(
    String requestId,
    String resolution,
  ) async {
    try {
      final updates = {
        'status': ServiceRequestStatus.resolved.toString().split('.').last,
        'resolution': resolution,
        'resolved_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      return await updateServiceRequest(requestId, updates);
    } catch (e) {
      throw FirestoreException('Failed to resolve service request: $e');
    }
  }

  /// Upvote service request
  Future<ServiceRequest> upvoteServiceRequest(
    String requestId,
    String userId,
  ) async {
    try {
      final doc = await _serviceRequestsCollection.doc(requestId).get();
      if (!doc.exists) {
        throw FirestoreException('Service request not found');
      }

      final request = ServiceRequest.fromJson(
        doc.data() as Map<String, dynamic>,
      );
      final upvotedBy = List<String>.from(request.upvotedBy);

      if (upvotedBy.contains(userId)) {
        // Remove upvote
        upvotedBy.remove(userId);
      } else {
        // Add upvote
        upvotedBy.add(userId);
      }

      final updates = {
        'upvoted_by': upvotedBy,
        'upvote_count': upvotedBy.length,
        'updated_at': DateTime.now().toIso8601String(),
      };

      return await updateServiceRequest(requestId, updates);
    } catch (e) {
      throw FirestoreException('Failed to upvote service request: $e');
    }
  }

  /// Get service request statistics
  Future<Map<String, int>> getServiceRequestStats() async {
    try {
      final snapshot = await _serviceRequestsCollection.get();
      final requests =
          snapshot.docs
              .map(
                (doc) =>
                    ServiceRequest.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

      return {
        'total_requests': requests.length,
        'open_requests':
            requests.where((r) => r.status == ServiceRequestStatus.open).length,
        'in_progress_requests':
            requests
                .where((r) => r.status == ServiceRequestStatus.inProgress)
                .length,
        'resolved_requests':
            requests
                .where((r) => r.status == ServiceRequestStatus.resolved)
                .length,
        'urgent_requests': requests.where((r) => r.isUrgent).length,
        'overdue_requests': requests.where((r) => r.isOverdue).length,
      };
    } catch (e) {
      throw FirestoreException('Failed to get service request stats: $e');
    }
  }

  // USER PROFILE OPERATIONS

  /// Create user profile
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
    } catch (e) {
      throw FirestoreException('Failed to create user profile: $e');
    }
  }

  /// Get user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    print('Fetching user profile for $uid');
    try {
      final doc = await _usersCollection.doc(uid).get();
      print('Document exists: ${doc.exists}');
      if (doc.exists) {
        print('User data: ${doc.data()}');
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      print('No user document found for $uid');
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw FirestoreException('Failed to update user profile: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw FirestoreException('Failed to delete user profile: $e');
    }
  }

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers({
    UserRole? role,
    bool? isActive,
    int? limit,
  }) async {
    try {
      Query query = _usersCollection;

      if (role != null) {
        query = query.where('role', isEqualTo: role.toString().split('.').last);
      }

      if (isActive != null) {
        query = query.where('is_active', isEqualTo: isActive);
      }

      query = query.orderBy('created_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get users: $e');
    }
  }

  /// Search users by display name or email
  Future<List<UserModel>> searchUsers(String searchQuery) async {
    try {
      final snapshot =
          await _usersCollection.where('is_active', isEqualTo: true).get();

      final users =
          snapshot.docs
              .map(
                (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .where(
                (user) =>
                    user.displayName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    user.email.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();

      return users;
    } catch (e) {
      throw FirestoreException('Failed to search users: $e');
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStats() async {
    try {
      final snapshot = await _usersCollection.get();
      final users =
          snapshot.docs
              .map(
                (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

      return {
        'total_users': users.length,
        'active_users': users.where((u) => u.isActive).length,
        'verified_users': users.where((u) => u.isEmailVerified).length,
        'residents': users.where((u) => u.role == UserRole.resident).length,
        'business_owners':
            users.where((u) => u.role == UserRole.businessOwner).length,
        'admins': users.where((u) => u.role == UserRole.admin).length,
        'moderators': users.where((u) => u.role == UserRole.moderator).length,
      };
    } catch (e) {
      throw FirestoreException('Failed to get user stats: $e');
    }
  }

  /// Listen to user profile changes
  Stream<UserModel?> listenToUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
