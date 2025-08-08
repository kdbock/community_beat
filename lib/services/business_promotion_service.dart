// lib/services/business_promotion_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_promotion.dart';

class BusinessPromotionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'business_promotions';

  // Create a new promotion
  static Future<String> createPromotion(BusinessPromotion promotion) async {
    try {
      final docRef = await _firestore.collection(_collection).add(promotion.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create promotion: $e');
    }
  }

  // Update an existing promotion
  static Future<void> updatePromotion(String promotionId, BusinessPromotion promotion) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(promotionId)
          .update(promotion.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Failed to update promotion: $e');
    }
  }

  // Delete a promotion
  static Future<void> deletePromotion(String promotionId) async {
    try {
      await _firestore.collection(_collection).doc(promotionId).delete();
    } catch (e) {
      throw Exception('Failed to delete promotion: $e');
    }
  }

  // Get promotions for a specific business
  static Future<List<BusinessPromotion>> getBusinessPromotions(
    String businessId, {
    PromotionStatus? status,
    bool activeOnly = false,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString());
      }

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => BusinessPromotion.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get business promotions: $e');
    }
  }

  // Get active promotions for public display
  static Future<List<BusinessPromotion>> getActivePromotions({
    String? businessId,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: PromotionStatus.active.toString())
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final promotions = snapshot.docs
          .map((doc) => BusinessPromotion.fromFirestore(doc))
          .where((promotion) => promotion.isCurrentlyActive)
          .toList();

      // Filter by tags if provided
      if (tags != null && tags.isNotEmpty) {
        return promotions.where((promotion) {
          return promotion.tags.any((tag) => tags.contains(tag));
        }).toList();
      }

      return promotions;
    } catch (e) {
      throw Exception('Failed to get active promotions: $e');
    }
  }

  // Get a specific promotion
  static Future<BusinessPromotion?> getPromotion(String promotionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(promotionId).get();
      if (doc.exists) {
        return BusinessPromotion.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get promotion: $e');
    }
  }

  // Get promotion by promo code
  static Future<BusinessPromotion?> getPromotionByCode(String promoCode) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('promoCode', isEqualTo: promoCode)
          .where('status', isEqualTo: PromotionStatus.active.toString())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final promotion = BusinessPromotion.fromFirestore(snapshot.docs.first);
        return promotion.isCurrentlyActive ? promotion : null;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get promotion by code: $e');
    }
  }

  // Update promotion status
  static Future<void> updatePromotionStatus(String promotionId, PromotionStatus status) async {
    try {
      await _firestore.collection(_collection).doc(promotionId).update({
        'status': status.toString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update promotion status: $e');
    }
  }

  // Increment promotion usage
  static Future<void> incrementUsage(String promotionId) async {
    try {
      await _firestore.collection(_collection).doc(promotionId).update({
        'currentUses': FieldValue.increment(1),
        'analytics.redeems': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to increment promotion usage: $e');
    }
  }

  // Track promotion view
  static Future<void> trackView(String promotionId) async {
    try {
      await _firestore.collection(_collection).doc(promotionId).update({
        'analytics.views': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail for analytics
      print('Failed to track promotion view: $e');
    }
  }

  // Track promotion click
  static Future<void> trackClick(String promotionId) async {
    try {
      await _firestore.collection(_collection).doc(promotionId).update({
        'analytics.clicks': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail for analytics
      print('Failed to track promotion click: $e');
    }
  }

  // Get promotion analytics
  static Future<Map<String, dynamic>> getPromotionAnalytics(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .get();

      final promotions = snapshot.docs
          .map((doc) => BusinessPromotion.fromFirestore(doc))
          .toList();

      int totalPromotions = promotions.length;
      int activePromotions = promotions.where((p) => p.isCurrentlyActive).length;
      int expiredPromotions = promotions.where((p) => p.isExpired).length;
      int totalViews = promotions.fold(0, (sum, p) => sum + p.viewCount);
      int totalClicks = promotions.fold(0, (sum, p) => sum + p.clickCount);
      int totalRedeems = promotions.fold(0, (sum, p) => sum + p.redeemCount);

      double avgClickThroughRate = 0.0;
      double avgConversionRate = 0.0;

      if (promotions.isNotEmpty) {
        avgClickThroughRate = promotions
            .map((p) => p.clickThroughRate)
            .reduce((a, b) => a + b) / promotions.length;
        
        avgConversionRate = promotions
            .map((p) => p.conversionRate)
            .reduce((a, b) => a + b) / promotions.length;
      }

      return {
        'totalPromotions': totalPromotions,
        'activePromotions': activePromotions,
        'expiredPromotions': expiredPromotions,
        'totalViews': totalViews,
        'totalClicks': totalClicks,
        'totalRedeems': totalRedeems,
        'avgClickThroughRate': avgClickThroughRate,
        'avgConversionRate': avgConversionRate,
        'topPerformingPromotions': promotions
            .where((p) => p.viewCount > 0)
            .toList()
            ..sort((a, b) => b.clickThroughRate.compareTo(a.clickThroughRate))
            ..take(5)
            .toList(),
      };
    } catch (e) {
      throw Exception('Failed to get promotion analytics: $e');
    }
  }

  // Validate promo code
  static Future<Map<String, dynamic>> validatePromoCode(String promoCode) async {
    try {
      final promotion = await getPromotionByCode(promoCode);
      
      if (promotion == null) {
        return {
          'valid': false,
          'message': 'Invalid promo code',
        };
      }

      if (!promotion.isCurrentlyActive) {
        return {
          'valid': false,
          'message': 'This promotion is no longer active',
        };
      }

      if (promotion.isUsageLimitReached) {
        return {
          'valid': false,
          'message': 'This promotion has reached its usage limit',
        };
      }

      return {
        'valid': true,
        'promotion': promotion,
        'message': 'Valid promo code',
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Error validating promo code',
      };
    }
  }

  // Get trending promotions (most viewed/clicked)
  static Future<List<BusinessPromotion>> getTrendingPromotions({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: PromotionStatus.active.toString())
          .where('isActive', isEqualTo: true)
          .orderBy('analytics.views', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BusinessPromotion.fromFirestore(doc))
          .where((promotion) => promotion.isCurrentlyActive)
          .toList();
    } catch (e) {
      throw Exception('Failed to get trending promotions: $e');
    }
  }

  // Search promotions
  static Future<List<BusinessPromotion>> searchPromotions(
    String query, {
    String? businessId,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore
          .collection(_collection)
          .where('status', isEqualTo: PromotionStatus.active.toString())
          .where('isActive', isEqualTo: true);

      if (businessId != null) {
        firestoreQuery = firestoreQuery.where('businessId', isEqualTo: businessId);
      }

      final snapshot = await firestoreQuery.limit(limit * 2).get(); // Get more to filter

      final promotions = snapshot.docs
          .map((doc) => BusinessPromotion.fromFirestore(doc))
          .where((promotion) => promotion.isCurrentlyActive)
          .where((promotion) {
            final searchText = query.toLowerCase();
            return promotion.title.toLowerCase().contains(searchText) ||
                   promotion.description.toLowerCase().contains(searchText) ||
                   promotion.tags.any((tag) => tag.toLowerCase().contains(searchText));
          })
          .toList();

      // Filter by tags if provided
      if (tags != null && tags.isNotEmpty) {
        return promotions.where((promotion) {
          return promotion.tags.any((tag) => tags.contains(tag));
        }).take(limit).toList();
      }

      return promotions.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search promotions: $e');
    }
  }
}