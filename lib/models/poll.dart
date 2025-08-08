// lib/models/poll.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final List<PollOption> options;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool allowMultipleVotes;
  final bool isAnonymous;
  final PollCategory category;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.options,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.allowMultipleVotes = false,
    this.isAnonymous = false,
    required this.category,
    this.tags = const [],
    this.metadata,
  });

  // Total votes across all options
  int get totalVotes => options.fold(0, (total, option) => total + option.voteCount);

  // Check if poll has expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  // Check if poll is currently votable
  bool get canVote => isActive && !isExpired;

  // Get winning option(s)
  List<PollOption> get winningOptions {
    if (options.isEmpty) return [];
    final maxVotes = options.map((o) => o.voteCount).reduce((a, b) => a > b ? a : b);
    return options.where((o) => o.voteCount == maxVotes).toList();
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'options': options.map((o) => o.toFirestore()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'is_active': isActive,
      'allow_multiple_votes': allowMultipleVotes,
      'is_anonymous': isAnonymous,
      'category': category.name,
      'tags': tags,
      'metadata': metadata ?? {},
    };
  }

  // Create from Firestore document
  factory Poll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Poll(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creator_id'] ?? '',
      creatorName: data['creator_name'] ?? '',
      options: (data['options'] as List<dynamic>? ?? [])
          .map((o) => PollOption.fromMap(o as Map<String, dynamic>))
          .toList(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expiresAt: data['expires_at'] != null 
          ? (data['expires_at'] as Timestamp).toDate() 
          : null,
      isActive: data['is_active'] ?? true,
      allowMultipleVotes: data['allow_multiple_votes'] ?? false,
      isAnonymous: data['is_anonymous'] ?? false,
      category: PollCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => PollCategory.general,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Poll copyWith({
    String? title,
    String? description,
    List<PollOption>? options,
    DateTime? expiresAt,
    bool? isActive,
    bool? allowMultipleVotes,
    bool? isAnonymous,
    PollCategory? category,
    List<String>? tags,
  }) {
    return Poll(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId,
      creatorName: creatorName,
      options: options ?? this.options,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      allowMultipleVotes: allowMultipleVotes ?? this.allowMultipleVotes,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      metadata: metadata,
    );
  }
}

class PollOption {
  final String id;
  final String text;
  final String? description;
  final int voteCount;
  final Color? color;
  final IconData? icon;

  PollOption({
    required this.id,
    required this.text,
    this.description,
    this.voteCount = 0,
    this.color,
    this.icon,
  });

  // Calculate percentage of total votes
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (voteCount / totalVotes) * 100;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'text': text,
      'description': description,
      'vote_count': voteCount,
      'color': color?.value,
      'icon': icon?.codePoint,
    };
  }

  factory PollOption.fromMap(Map<String, dynamic> data) {
    return PollOption(
      id: data['id'] ?? '',
      text: data['text'] ?? '',
      description: data['description'],
      voteCount: data['vote_count'] ?? 0,
      color: data['color'] != null ? Color(data['color']) : null,
      icon: data['icon'] != null ? IconData(data['icon'], fontFamily: 'MaterialIcons') : null,
    );
  }

  PollOption copyWith({
    String? text,
    String? description,
    int? voteCount,
    Color? color,
    IconData? icon,
  }) {
    return PollOption(
      id: id,
      text: text ?? this.text,
      description: description ?? this.description,
      voteCount: voteCount ?? this.voteCount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

class PollVote {
  final String id;
  final String pollId;
  final String userId;
  final List<String> selectedOptionIds;
  final DateTime votedAt;
  final String? userDisplayName;

  PollVote({
    required this.id,
    required this.pollId,
    required this.userId,
    required this.selectedOptionIds,
    required this.votedAt,
    this.userDisplayName,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'poll_id': pollId,
      'user_id': userId,
      'selected_option_ids': selectedOptionIds,
      'voted_at': Timestamp.fromDate(votedAt),
      'user_display_name': userDisplayName,
    };
  }

  factory PollVote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PollVote(
      id: doc.id,
      pollId: data['poll_id'] ?? '',
      userId: data['user_id'] ?? '',
      selectedOptionIds: List<String>.from(data['selected_option_ids'] ?? []),
      votedAt: (data['voted_at'] as Timestamp).toDate(),
      userDisplayName: data['user_display_name'],
    );
  }
}

enum PollCategory {
  general,
  community,
  events,
  infrastructure,
  safety,
  environment,
  business,
  education,
  health,
  transportation;

  String get displayName {
    switch (this) {
      case PollCategory.general:
        return 'General';
      case PollCategory.community:
        return 'Community';
      case PollCategory.events:
        return 'Events';
      case PollCategory.infrastructure:
        return 'Infrastructure';
      case PollCategory.safety:
        return 'Safety';
      case PollCategory.environment:
        return 'Environment';
      case PollCategory.business:
        return 'Business';
      case PollCategory.education:
        return 'Education';
      case PollCategory.health:
        return 'Health';
      case PollCategory.transportation:
        return 'Transportation';
    }
  }

  IconData get icon {
    switch (this) {
      case PollCategory.general:
        return Icons.poll;
      case PollCategory.community:
        return Icons.people;
      case PollCategory.events:
        return Icons.event;
      case PollCategory.infrastructure:
        return Icons.construction;
      case PollCategory.safety:
        return Icons.security;
      case PollCategory.environment:
        return Icons.eco;
      case PollCategory.business:
        return Icons.business;
      case PollCategory.education:
        return Icons.school;
      case PollCategory.health:
        return Icons.health_and_safety;
      case PollCategory.transportation:
        return Icons.directions_bus;
    }
  }

  Color get color {
    switch (this) {
      case PollCategory.general:
        return Colors.blue;
      case PollCategory.community:
        return Colors.purple;
      case PollCategory.events:
        return Colors.orange;
      case PollCategory.infrastructure:
        return Colors.brown;
      case PollCategory.safety:
        return Colors.red;
      case PollCategory.environment:
        return Colors.green;
      case PollCategory.business:
        return Colors.indigo;
      case PollCategory.education:
        return Colors.teal;
      case PollCategory.health:
        return Colors.pink;
      case PollCategory.transportation:
        return Colors.cyan;
    }
  }
}