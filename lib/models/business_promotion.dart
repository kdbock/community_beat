// lib/models/business_promotion.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum PromotionType {
  percentage,
  fixedAmount,
  buyOneGetOne,
  freeItem,
  bundle,
  other,
}

enum PromotionStatus {
  draft,
  active,
  paused,
  expired,
  cancelled,
}

class BusinessPromotion {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final PromotionType type;
  final PromotionStatus status;
  final double? discountPercentage;
  final double? discountAmount;
  final String? freeItem;
  final List<String> applicableItems;
  final double? minimumPurchase;
  final int? maxUses;
  final int currentUses;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> imageUrls;
  final String? promoCode;
  final bool requiresCode;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> analytics;

  const BusinessPromotion({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.discountPercentage,
    this.discountAmount,
    this.freeItem,
    this.applicableItems = const [],
    this.minimumPurchase,
    this.maxUses,
    this.currentUses = 0,
    required this.startDate,
    required this.endDate,
    this.imageUrls = const [],
    this.promoCode,
    this.requiresCode = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.analytics = const {},
  });

  factory BusinessPromotion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BusinessPromotion(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: PromotionType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => PromotionType.other,
      ),
      status: PromotionStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PromotionStatus.draft,
      ),
      discountPercentage: data['discountPercentage']?.toDouble(),
      discountAmount: data['discountAmount']?.toDouble(),
      freeItem: data['freeItem'],
      applicableItems: List<String>.from(data['applicableItems'] ?? []),
      minimumPurchase: data['minimumPurchase']?.toDouble(),
      maxUses: data['maxUses'],
      currentUses: data['currentUses'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      promoCode: data['promoCode'],
      requiresCode: data['requiresCode'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'title': title,
      'description': description,
      'type': type.toString(),
      'status': status.toString(),
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'freeItem': freeItem,
      'applicableItems': applicableItems,
      'minimumPurchase': minimumPurchase,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'imageUrls': imageUrls,
      'promoCode': promoCode,
      'requiresCode': requiresCode,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'analytics': analytics,
    };
  }

  BusinessPromotion copyWith({
    String? id,
    String? businessId,
    String? title,
    String? description,
    PromotionType? type,
    PromotionStatus? status,
    double? discountPercentage,
    double? discountAmount,
    String? freeItem,
    List<String>? applicableItems,
    double? minimumPurchase,
    int? maxUses,
    int? currentUses,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? imageUrls,
    String? promoCode,
    bool? requiresCode,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? analytics,
  }) {
    return BusinessPromotion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      freeItem: freeItem ?? this.freeItem,
      applicableItems: applicableItems ?? this.applicableItems,
      minimumPurchase: minimumPurchase ?? this.minimumPurchase,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrls: imageUrls ?? this.imageUrls,
      promoCode: promoCode ?? this.promoCode,
      requiresCode: requiresCode ?? this.requiresCode,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      analytics: analytics ?? this.analytics,
    );
  }

  // Computed properties
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isStarted => DateTime.now().isAfter(startDate);
  bool get isCurrentlyActive => isActive && isStarted && !isExpired && status == PromotionStatus.active;
  bool get hasUsageLimit => maxUses != null;
  bool get isUsageLimitReached => hasUsageLimit && currentUses >= maxUses!;
  
  String get statusText {
    if (isExpired) return 'Expired';
    if (!isStarted) return 'Scheduled';
    if (isUsageLimitReached) return 'Limit Reached';
    return status.toString().split('.').last.toUpperCase();
  }

  String get typeText {
    switch (type) {
      case PromotionType.percentage:
        return '${discountPercentage?.round()}% Off';
      case PromotionType.fixedAmount:
        return '\$${discountAmount?.toStringAsFixed(2)} Off';
      case PromotionType.buyOneGetOne:
        return 'Buy One Get One';
      case PromotionType.freeItem:
        return 'Free $freeItem';
      case PromotionType.bundle:
        return 'Bundle Deal';
      case PromotionType.other:
        return 'Special Offer';
    }
  }

  String get timeRemaining {
    if (isExpired) return 'Expired';
    
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} left';
    } else {
      return 'Expires soon';
    }
  }

  double get usagePercentage {
    if (!hasUsageLimit) return 0.0;
    return (currentUses / maxUses!).clamp(0.0, 1.0);
  }

  int get viewCount => analytics['views'] ?? 0;
  int get clickCount => analytics['clicks'] ?? 0;
  int get redeemCount => analytics['redeems'] ?? 0;
  
  double get clickThroughRate {
    if (viewCount == 0) return 0.0;
    return (clickCount / viewCount) * 100;
  }

  double get conversionRate {
    if (clickCount == 0) return 0.0;
    return (redeemCount / clickCount) * 100;
  }
}