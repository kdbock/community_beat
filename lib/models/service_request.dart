// lib/models/service_request.dart

enum ServiceRequestStatus {
  open,
  inProgress,
  resolved,
  closed,
  cancelled,
}

enum ServiceRequestPriority {
  low,
  medium,
  high,
  urgent,
}

class ServiceRequest {
  final String id;
  final String title;
  final String description;
  final String category;
  final ServiceRequestPriority priority;
  final ServiceRequestStatus status;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String? assignedTo;
  final String? assignedToName;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final Map<String, String>? contactInfo;
  final List<String> imageUrls;
  final DateTime? preferredDate;
  final DateTime? resolvedDate;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isUrgent;
  final String? resolution;
  final int upvoteCount;
  final List<String> upvotedBy;

  ServiceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    this.assignedTo,
    this.assignedToName,
    this.location,
    this.address,
    this.latitude,
    this.longitude,
    this.contactInfo,
    this.imageUrls = const [],
    this.preferredDate,
    this.resolvedDate,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isUrgent = false,
    this.resolution,
    this.upvoteCount = 0,
    this.upvotedBy = const [],
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: ServiceRequestPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => ServiceRequestPriority.medium,
      ),
      status: ServiceRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ServiceRequestStatus.open,
      ),
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'] ?? '',
      requesterAvatar: json['requester_avatar'],
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      location: json['location'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      contactInfo: json['contact_info'] != null
          ? Map<String, String>.from(json['contact_info'])
          : null,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      preferredDate: json['preferred_date'] != null
          ? DateTime.parse(json['preferred_date'])
          : null,
      resolvedDate: json['resolved_date'] != null
          ? DateTime.parse(json['resolved_date'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isUrgent: json['is_urgent'] ?? false,
      resolution: json['resolution'],
      upvoteCount: json['upvote_count'] ?? 0,
      upvotedBy: List<String>.from(json['upvoted_by'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'requester_avatar': requesterAvatar,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contact_info': contactInfo,
      'image_urls': imageUrls,
      'preferred_date': preferredDate?.toIso8601String(),
      'resolved_date': resolvedDate?.toIso8601String(),
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_urgent': isUrgent,
      'resolution': resolution,
      'upvote_count': upvoteCount,
      'upvoted_by': upvotedBy,
    };
  }

  ServiceRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    ServiceRequestPriority? priority,
    ServiceRequestStatus? status,
    String? requesterId,
    String? requesterName,
    String? requesterAvatar,
    String? assignedTo,
    String? assignedToName,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    Map<String, String>? contactInfo,
    List<String>? imageUrls,
    DateTime? preferredDate,
    DateTime? resolvedDate,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUrgent,
    String? resolution,
    int? upvoteCount,
    List<String>? upvotedBy,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterAvatar: requesterAvatar ?? this.requesterAvatar,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactInfo: contactInfo ?? this.contactInfo,
      imageUrls: imageUrls ?? this.imageUrls,
      preferredDate: preferredDate ?? this.preferredDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUrgent: isUrgent ?? this.isUrgent,
      resolution: resolution ?? this.resolution,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      upvotedBy: upvotedBy ?? this.upvotedBy,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ServiceRequestStatus.open:
        return 'Open';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.resolved:
        return 'Resolved';
      case ServiceRequestStatus.closed:
        return 'Closed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case ServiceRequestPriority.low:
        return 'Low';
      case ServiceRequestPriority.medium:
        return 'Medium';
      case ServiceRequestPriority.high:
        return 'High';
      case ServiceRequestPriority.urgent:
        return 'Urgent';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
    }
  }

  bool get isOverdue {
    if (preferredDate == null || status == ServiceRequestStatus.resolved) {
      return false;
    }
    return DateTime.now().isAfter(preferredDate!);
  }

  bool get isAssigned => assignedTo != null;

  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return '🔧';
      case 'safety':
        return '🚨';
      case 'utilities':
        return '💡';
      case 'transportation':
        return '🚗';
      case 'environment':
        return '🌱';
      case 'community':
        return '👥';
      default:
        return '📋';
    }
  }
}