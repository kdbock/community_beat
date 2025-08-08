// lib/services/business_review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_review.dart';


class BusinessReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'business_reviews';
  static const String _businessCollection = 'businesses';

  // Create a new review
  static Future<String> createReview(BusinessReview review) async {
    try {
      final docRef = await _firestore.collection(_collection).add(review.toJson());
      
      // Update business rating and review count
      await _updateBusinessRating(review.businessId);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Get reviews for a specific business
  static Future<List<BusinessReview>> getBusinessReviews(
    String businessId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    ReviewSortBy sortBy = ReviewSortBy.newest,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('business_id', isEqualTo: businessId)
          .where('status', isEqualTo: 'active');

      // Apply sorting
      switch (sortBy) {
        case ReviewSortBy.newest:
          query = query.orderBy('created_at', descending: true);
          break;
        case ReviewSortBy.oldest:
          query = query.orderBy('created_at', descending: false);
          break;
        case ReviewSortBy.highestRated:
          query = query.orderBy('rating', descending: true);
          break;
        case ReviewSortBy.lowestRated:
          query = query.orderBy('rating', descending: false);
          break;
        case ReviewSortBy.mostHelpful:
          // Note: Firestore doesn't support ordering by array length directly
          // We'll sort in memory after fetching
          query = query.orderBy('created_at', descending: true);
          break;
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      List<BusinessReview> reviews = snapshot.docs
          .map((doc) => BusinessReview.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      // Sort by most helpful if needed (in memory)
      if (sortBy == ReviewSortBy.mostHelpful) {
        reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
      }

      return reviews;
    } catch (e) {
      throw Exception('Failed to get business reviews: $e');
    }
  }

  // Get reviews by a specific user
  static Future<List<BusinessReview>> getUserReviews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BusinessReview.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reviews: $e');
    }
  }

  // Update a review
  static Future<void> updateReview(String reviewId, BusinessReview review) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update(
            review.copyWith(updatedAt: DateTime.now()).toJson(),
          );

      // Update business rating
      await _updateBusinessRating(review.businessId);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  static Future<void> deleteReview(String reviewId, String businessId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
      
      // Update business rating
      await _updateBusinessRating(businessId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Mark review as helpful
  static Future<void> markReviewHelpful(String reviewId, String userId, bool isHelpful) async {
    try {
      final reviewRef = _firestore.collection(_collection).doc(reviewId);
      
      if (isHelpful) {
        await reviewRef.update({
          'helpful_votes': FieldValue.arrayUnion([userId]),
        });
      } else {
        await reviewRef.update({
          'helpful_votes': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }

  // Report a review
  static Future<void> reportReview(String reviewId, String userId, String reason) async {
    try {
      final reviewRef = _firestore.collection(_collection).doc(reviewId);
      
      await reviewRef.update({
        'reported_by': FieldValue.arrayUnion([userId]),
      });

      // Create a report document for admin review
      await _firestore.collection('review_reports').add({
        'review_id': reviewId,
        'reported_by': userId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report review: $e');
    }
  }

  // Add business response to review
  static Future<void> addBusinessResponse(
    String reviewId,
    String response,
    String businessOwnerId,
  ) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'business_response': response,
        'business_response_date': DateTime.now().toIso8601String(),
        'business_response_by': businessOwnerId,
      });
    } catch (e) {
      throw Exception('Failed to add business response: $e');
    }
  }

  // Get review summary for a business
  static Future<ReviewSummary> getReviewSummary(String businessId) async {
    try {
      final reviews = await getBusinessReviews(businessId, limit: 1000);
      return ReviewSummary.fromReviews(reviews);
    } catch (e) {
      throw Exception('Failed to get review summary: $e');
    }
  }

  // Check if user has reviewed a business
  static Future<BusinessReview?> getUserReviewForBusiness(
    String userId,
    String businessId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .where('business_id', isEqualTo: businessId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return BusinessReview.fromJson({
        ...snapshot.docs.first.data(),
        'id': snapshot.docs.first.id,
      });
    } catch (e) {
      throw Exception('Failed to check user review: $e');
    }
  }

  // Get reviews with filters
  static Future<List<BusinessReview>> getFilteredReviews(
    String businessId, {
    int? minRating,
    int? maxRating,
    bool? verifiedOnly,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('business_id', isEqualTo: businessId)
          .where('status', isEqualTo: 'active');

      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating.toDouble());
      }

      if (maxRating != null) {
        query = query.where('rating', isLessThanOrEqualTo: maxRating.toDouble());
      }

      if (verifiedOnly == true) {
        query = query.where('is_verified', isEqualTo: true);
      }

      query = query.orderBy('created_at', descending: true).limit(limit);

      final snapshot = await query.get();
      List<BusinessReview> reviews = snapshot.docs
          .map((doc) => BusinessReview.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      // Filter by tags if specified (in memory)
      if (tags != null && tags.isNotEmpty) {
        reviews = reviews.where((review) {
          return tags.any((tag) => review.tags.contains(tag));
        }).toList();
      }

      return reviews;
    } catch (e) {
      throw Exception('Failed to get filtered reviews: $e');
    }
  }

  // Private method to update business rating
  static Future<void> _updateBusinessRating(String businessId) async {
    try {
      final summary = await getReviewSummary(businessId);
      
      await _firestore.collection(_businessCollection).doc(businessId).update({
        'rating': summary.averageRating,
        'review_count': summary.totalReviews,
      });
    } catch (e) {
      // Don't throw error for rating update failure
      print('Warning: Failed to update business rating: $e');
    }
  }

  // Get trending/popular reviews
  static Future<List<BusinessReview>> getTrendingReviews({
    int limit = 10,
    int daysBack = 7,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .where('created_at', isGreaterThan: cutoffDate.toIso8601String())
          .orderBy('created_at', descending: true)
          .limit(limit * 3) // Get more to sort by helpful votes
          .get();

      List<BusinessReview> reviews = snapshot.docs
          .map((doc) => BusinessReview.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      // Sort by helpful votes and take top results
      reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
      
      return reviews.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get trending reviews: $e');
    }
  }

  // Moderate review (admin function)
  static Future<void> moderateReview(
    String reviewId,
    ReviewStatus status,
    String moderatorId,
  ) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'status': status.toString().split('.').last,
        'moderated_by': moderatorId,
        'moderated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to moderate review: $e');
    }
  }
}

enum ReviewSortBy {
  newest,
  oldest,
  highestRated,
  lowestRated,
  mostHelpful,
}