// lib/models/report.dart

import 'package:flutter/material.dart';

enum ReportType {
  spam,
  harassment,
  inappropriateContent,
  misinformation,
  violence,
  hateSpeech,
  copyright,
  other,
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

enum ReportedContentType {
  post,
  comment,
  event,
  serviceRequest,
  business,
  user,
}

class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedContentId;
  final ReportedContentType contentType;
  final String? reportedUserId; // User who created the content
  final String? reportedUserName;
  final ReportType reportType;
  final String reason;
  final String? additionalDetails;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewerName;
  final String? moderationAction;
  final String? moderationNotes;
  final Map<String, dynamic> contentSnapshot; // Snapshot of reported content

  Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedContentId,
    required this.contentType,
    this.reportedUserId,
    this.reportedUserName,
    required this.reportType,
    required this.reason,
    this.additionalDetails,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewerName,
    this.moderationAction,
    this.moderationNotes,
    this.contentSnapshot = const {},
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      reporterId: json['reporter_id'] ?? '',
      reporterName: json['reporter_name'] ?? '',
      reportedContentId: json['reported_content_id'] ?? '',
      contentType: ReportedContentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['content_type'],
        orElse: () => ReportedContentType.post,
      ),
      reportedUserId: json['reported_user_id'],
      reportedUserName: json['reported_user_name'],
      reportType: ReportType.values.firstWhere(
        (e) => e.toString().split('.').last == json['report_type'],
        orElse: () => ReportType.other,
      ),
      reason: json['reason'] ?? '',
      additionalDetails: json['additional_details'],
      status: ReportStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      reviewedBy: json['reviewed_by'],
      reviewerName: json['reviewer_name'],
      moderationAction: json['moderation_action'],
      moderationNotes: json['moderation_notes'],
      contentSnapshot: Map<String, dynamic>.from(json['content_snapshot'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reported_content_id': reportedContentId,
      'content_type': contentType.toString().split('.').last,
      'reported_user_id': reportedUserId,
      'reported_user_name': reportedUserName,
      'report_type': reportType.toString().split('.').last,
      'reason': reason,
      'additional_details': additionalDetails,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'reviewer_name': reviewerName,
      'moderation_action': moderationAction,
      'moderation_notes': moderationNotes,
      'content_snapshot': contentSnapshot,
    };
  }

  Report copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? reportedContentId,
    ReportedContentType? contentType,
    String? reportedUserId,
    String? reportedUserName,
    ReportType? reportType,
    String? reason,
    String? additionalDetails,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewerName,
    String? moderationAction,
    String? moderationNotes,
    Map<String, dynamic>? contentSnapshot,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reportedContentId: reportedContentId ?? this.reportedContentId,
      contentType: contentType ?? this.contentType,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      reportType: reportType ?? this.reportType,
      reason: reason ?? this.reason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerName: reviewerName ?? this.reviewerName,
      moderationAction: moderationAction ?? this.moderationAction,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      contentSnapshot: contentSnapshot ?? this.contentSnapshot,
    );
  }
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.spam:
        return 'Spam';
      case ReportType.harassment:
        return 'Harassment';
      case ReportType.inappropriateContent:
        return 'Inappropriate Content';
      case ReportType.misinformation:
        return 'Misinformation';
      case ReportType.violence:
        return 'Violence';
      case ReportType.hateSpeech:
        return 'Hate Speech';
      case ReportType.copyright:
        return 'Copyright Violation';
      case ReportType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportType.spam:
        return 'Unwanted or repetitive content';
      case ReportType.harassment:
        return 'Bullying or harassment of users';
      case ReportType.inappropriateContent:
        return 'Content not suitable for the community';
      case ReportType.misinformation:
        return 'False or misleading information';
      case ReportType.violence:
        return 'Content promoting violence';
      case ReportType.hateSpeech:
        return 'Content targeting individuals or groups';
      case ReportType.copyright:
        return 'Unauthorized use of copyrighted material';
      case ReportType.other:
        return 'Other policy violations';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.spam:
        return Icons.block;
      case ReportType.harassment:
        return Icons.person_off;
      case ReportType.inappropriateContent:
        return Icons.warning;
      case ReportType.misinformation:
        return Icons.fact_check;
      case ReportType.violence:
        return Icons.dangerous;
      case ReportType.hateSpeech:
        return Icons.sentiment_very_dissatisfied;
      case ReportType.copyright:
        return Icons.copyright;
      case ReportType.other:
        return Icons.report_problem;
    }
  }
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.underReview:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.pending:
        return Icons.schedule;
      case ReportStatus.underReview:
        return Icons.visibility;
      case ReportStatus.resolved:
        return Icons.check_circle;
      case ReportStatus.dismissed:
        return Icons.cancel;
    }
  }
}

extension ReportedContentTypeExtension on ReportedContentType {
  String get displayName {
    switch (this) {
      case ReportedContentType.post:
        return 'Post';
      case ReportedContentType.comment:
        return 'Comment';
      case ReportedContentType.event:
        return 'Event';
      case ReportedContentType.serviceRequest:
        return 'Service Request';
      case ReportedContentType.business:
        return 'Business';
      case ReportedContentType.user:
        return 'User Profile';
    }
  }

  String get collectionName {
    switch (this) {
      case ReportedContentType.post:
        return 'posts';
      case ReportedContentType.comment:
        return 'comments';
      case ReportedContentType.event:
        return 'events';
      case ReportedContentType.serviceRequest:
        return 'service_requests';
      case ReportedContentType.business:
        return 'businesses';
      case ReportedContentType.user:
        return 'users';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportedContentType.post:
        return Icons.article;
      case ReportedContentType.comment:
        return Icons.comment;
      case ReportedContentType.event:
        return Icons.event;
      case ReportedContentType.serviceRequest:
        return Icons.build;
      case ReportedContentType.business:
        return Icons.business;
      case ReportedContentType.user:
        return Icons.person;
    }
  }
}