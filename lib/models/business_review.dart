// lib/models/business_review.dart

class BusinessReview {
  final String id;
  final String businessId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating; // 1-5 stars
  final String title;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified; // Verified purchase/visit
  final List<String> helpfulVotes; // User IDs who found this helpful
  final List<String> reportedBy; // User IDs who reported this review
  final ReviewStatus status;
  final String? businessResponse;
  final DateTime? businessResponseDate;
  final List<String> tags; // e.g., "Great Service", "Clean", "Fast"

  BusinessReview({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.title,
    required this.comment,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.helpfulVotes = const [],
    this.reportedBy = const [],
    this.status = ReviewStatus.active,
    this.businessResponse,
    this.businessResponseDate,
    this.tags = const [],
  });

  factory BusinessReview.fromJson(Map<String, dynamic> json) {
    return BusinessReview(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userPhotoUrl: json['user_photo_url'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      title: json['title'] ?? '',
      comment: json['comment'] ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isVerified: json['is_verified'] ?? false,
      helpfulVotes: List<String>.from(json['helpful_votes'] ?? []),
      reportedBy: List<String>.from(json['reported_by'] ?? []),
      status: ReviewStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ReviewStatus.active,
      ),
      businessResponse: json['business_response'],
      businessResponseDate: json['business_response_date'] != null 
          ? DateTime.parse(json['business_response_date']) 
          : null,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'rating': rating,
      'title': title,
      'comment': comment,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_verified': isVerified,
      'helpful_votes': helpfulVotes,
      'reported_by': reportedBy,
      'status': status.toString().split('.').last,
      'business_response': businessResponse,
      'business_response_date': businessResponseDate?.toIso8601String(),
      'tags': tags,
    };
  }

  BusinessReview copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? title,
    String? comment,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    List<String>? helpfulVotes,
    List<String>? reportedBy,
    ReviewStatus? status,
    String? businessResponse,
    DateTime? businessResponseDate,
    List<String>? tags,
  }) {
    return BusinessReview(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      reportedBy: reportedBy ?? this.reportedBy,
      status: status ?? this.status,
      businessResponse: businessResponse ?? this.businessResponse,
      businessResponseDate: businessResponseDate ?? this.businessResponseDate,
      tags: tags ?? this.tags,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  bool get hasBusinessResponse => businessResponse != null && businessResponse!.isNotEmpty;

  int get helpfulCount => helpfulVotes.length;

  bool isHelpfulBy(String userId) => helpfulVotes.contains(userId);

  bool isReportedBy(String userId) => reportedBy.contains(userId);

  String get ratingText {
    switch (rating.round()) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Very Good';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      default:
        return 'No Rating';
    }
  }
}

enum ReviewStatus {
  active,
  pending,
  hidden,
  removed,
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star rating -> count
  final List<String> topTags;
  final int verifiedReviews;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.topTags,
    required this.verifiedReviews,
  });

  factory ReviewSummary.fromReviews(List<BusinessReview> reviews) {
    if (reviews.isEmpty) {
      return ReviewSummary(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        topTags: [],
        verifiedReviews: 0,
      );
    }

    final activeReviews = reviews.where((r) => r.status == ReviewStatus.active).toList();
    
    final totalRating = activeReviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    final averageRating = activeReviews.isNotEmpty ? totalRating / activeReviews.length : 0.0;

    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = activeReviews.where((r) => r.rating.round() == i).length;
    }

    final allTags = <String>[];
    for (final review in activeReviews) {
      allTags.addAll(review.tags);
    }

    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }

    final topTags = tagCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5);

    final verifiedReviews = activeReviews.where((r) => r.isVerified).length;

    return ReviewSummary(
      averageRating: averageRating,
      totalReviews: activeReviews.length,
      ratingDistribution: ratingDistribution,
      topTags: topTags.map((e) => e.key).toList(),
      verifiedReviews: verifiedReviews,
    );
  }

  String get ratingText {
    if (totalReviews == 0) return 'No reviews yet';
    return '${averageRating.toStringAsFixed(1)} (${totalReviews} review${totalReviews == 1 ? '' : 's'})';
  }

  double getRatingPercentage(int stars) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[stars] ?? 0) / totalReviews;
  }
}