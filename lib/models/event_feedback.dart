// lib/models/event_feedback.dart

class EventFeedback {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final List<String> tags; // e.g., ['well-organized', 'fun', 'informative']
  final bool isAnonymous;

  EventFeedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.tags = const [],
    this.isAnonymous = false,
  });

  factory EventFeedback.fromJson(Map<String, dynamic> json) {
    return EventFeedback(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      rating: json['rating'] ?? 1,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      tags: List<String>.from(json['tags'] ?? []),
      isAnonymous: json['is_anonymous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
      'is_anonymous': isAnonymous,
    };
  }

  EventFeedback copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userEmail,
    int? rating,
    String? comment,
    DateTime? createdAt,
    List<String>? tags,
    bool? isAnonymous,
  }) {
    return EventFeedback(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}

class EventRating {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // star -> count
  final List<String> commonTags;

  EventRating({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    required this.commonTags,
  });

  factory EventRating.fromFeedbackList(List<EventFeedback> feedbacks) {
    if (feedbacks.isEmpty) {
      return EventRating(
        averageRating: 0.0,
        totalRatings: 0,
        ratingDistribution: {},
        commonTags: [],
      );
    }

    // Calculate average rating
    final totalRating = feedbacks.fold<int>(0, (sum, feedback) => sum + feedback.rating);
    final averageRating = totalRating / feedbacks.length;

    // Calculate rating distribution
    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = feedbacks.where((f) => f.rating == i).length;
    }

    // Get common tags
    final allTags = <String>[];
    for (final feedback in feedbacks) {
      allTags.addAll(feedback.tags);
    }
    
    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    
    final commonTags = tagCounts.entries
        .where((entry) => entry.value >= 2) // At least 2 mentions
        .map((entry) => entry.key)
        .take(5) // Top 5 tags
        .toList();

    return EventRating(
      averageRating: averageRating,
      totalRatings: feedbacks.length,
      ratingDistribution: ratingDistribution,
      commonTags: commonTags,
    );
  }
}

// Predefined feedback tags
class FeedbackTags {
  static const List<String> positive = [
    'well-organized',
    'fun',
    'informative',
    'engaging',
    'professional',
    'friendly',
    'valuable',
    'inspiring',
    'entertaining',
    'educational',
  ];

  static const List<String> neutral = [
    'crowded',
    'long',
    'short',
    'loud',
    'quiet',
    'indoor',
    'outdoor',
    'formal',
    'casual',
    'interactive',
  ];

  static const List<String> negative = [
    'disorganized',
    'boring',
    'confusing',
    'expensive',
    'poor-quality',
    'unprofessional',
    'disappointing',
    'waste-of-time',
    'overcrowded',
    'poorly-managed',
  ];

  static List<String> get all => [...positive, ...neutral, ...negative];
}