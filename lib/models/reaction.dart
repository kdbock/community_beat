// lib/models/reaction.dart

import 'package:flutter/material.dart';
import 'comment.dart';

class Reaction {
  final String id;
  final String contentId; // ID of the post, event, comment, etc.
  final ContentType contentType;
  final String userId;
  final String userName;
  final ReactionType reactionType;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.userId,
    required this.userName,
    required this.reactionType,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] ?? '',
      contentId: json['content_id'] ?? '',
      contentType: ContentType.values.firstWhere(
        (type) => type.name == json['content_type'],
        orElse: () => ContentType.post,
      ),
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      reactionType: ReactionType.values.firstWhere(
        (type) => type.name == json['reaction_type'],
        orElse: () => ReactionType.like,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'content_type': contentType.name,
      'user_id': userId,
      'user_name': userName,
      'reaction_type': reactionType.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Reaction copyWith({
    String? id,
    String? contentId,
    ContentType? contentType,
    String? userId,
    String? userName,
    ReactionType? reactionType,
    DateTime? createdAt,
  }) {
    return Reaction(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      reactionType: reactionType ?? this.reactionType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum ReactionType {
  like,
  love,
  laugh,
  wow,
  sad,
  angry,
}

extension ReactionTypeExtension on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.laugh:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
    }
  }

  String get displayName {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.laugh:
        return 'Laugh';
      case ReactionType.wow:
        return 'Wow';
      case ReactionType.sad:
        return 'Sad';
      case ReactionType.angry:
        return 'Angry';
    }
  }

  Color get color {
    switch (this) {
      case ReactionType.like:
        return const Color(0xFF1877F2); // Facebook blue
      case ReactionType.love:
        return const Color(0xFFE91E63); // Pink
      case ReactionType.laugh:
        return const Color(0xFFFFC107); // Amber
      case ReactionType.wow:
        return const Color(0xFFFFC107); // Amber
      case ReactionType.sad:
        return const Color(0xFFFFC107); // Amber
      case ReactionType.angry:
        return const Color(0xFFF44336); // Red
    }
  }
}

// Reaction summary for content
class ReactionSummary {
  final Map<ReactionType, int> reactionCounts;
  final int totalReactions;
  final ReactionType? userReaction; // Current user's reaction, if any
  final List<String> topReactors; // Names of people who reacted

  ReactionSummary({
    required this.reactionCounts,
    required this.totalReactions,
    this.userReaction,
    this.topReactors = const [],
  });

  factory ReactionSummary.fromReactions(
    List<Reaction> reactions, {
    String? currentUserId,
  }) {
    final reactionCounts = <ReactionType, int>{};
    ReactionType? userReaction;
    final reactorNames = <String>[];

    for (final reaction in reactions) {
      // Count reactions by type
      reactionCounts[reaction.reactionType] = 
          (reactionCounts[reaction.reactionType] ?? 0) + 1;
      
      // Check if current user has reacted
      if (currentUserId != null && reaction.userId == currentUserId) {
        userReaction = reaction.reactionType;
      }
      
      // Collect reactor names (limit to avoid too long lists)
      if (reactorNames.length < 10 && !reactorNames.contains(reaction.userName)) {
        reactorNames.add(reaction.userName);
      }
    }

    return ReactionSummary(
      reactionCounts: reactionCounts,
      totalReactions: reactions.length,
      userReaction: userReaction,
      topReactors: reactorNames,
    );
  }

  // Get the most popular reaction type
  ReactionType? get topReaction {
    if (reactionCounts.isEmpty) return null;
    
    return reactionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get top 3 reaction types
  List<ReactionType> get topReactions {
    final sorted = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(3).map((e) => e.key).toList();
  }

  // Check if user has reacted
  bool get hasUserReacted => userReaction != null;

  // Get count for specific reaction type
  int getCount(ReactionType type) => reactionCounts[type] ?? 0;

  // Generate reaction summary text
  String generateSummaryText() {
    if (totalReactions == 0) return '';
    
    if (totalReactions == 1) {
      return topReactors.isNotEmpty 
          ? '${topReactors.first} reacted'
          : '1 reaction';
    }
    
    if (topReactors.length == 1) {
      return '${topReactors.first} and ${totalReactions - 1} others reacted';
    }
    
    if (topReactors.length >= 2) {
      return '${topReactors[0]}, ${topReactors[1]} and ${totalReactions - 2} others reacted';
    }
    
    return '$totalReactions reactions';
  }
}