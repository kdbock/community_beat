// lib/models/post.dart

enum PostType {
  general,
  buySell,
  job,
  housing,
  lostFound,
  volunteer,
  service,
  event,
  business,
  other
}

// Extension for PostType to provide displayName
extension PostTypeExtension on PostType {
  String get displayName {
    switch (this) {
      case PostType.general:
        return 'General';
      case PostType.buySell:
        return 'Buy/Sell';
      case PostType.job:
        return 'Job';
      case PostType.housing:
        return 'Housing';
      case PostType.lostFound:
        return 'Lost & Found';
      case PostType.volunteer:
        return 'Volunteer';
      case PostType.service:
        return 'Service';
      case PostType.event:
        return 'Event';
      case PostType.business:
        return 'Business';
      case PostType.other:
        return 'Other';
    }
  }
}

class Post {
  final String id;
  final String title;
  final String description;
  final PostType type;
  final String category;
  final String authorName;
  final String? authorContact;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String> imageUrls;
  final double? price;
  final String? location;
  final bool isActive;
  final int viewCount;
  final List<String> tags;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.authorName,
    this.authorContact,
    required this.createdAt,
    this.expiresAt,
    this.imageUrls = const [],
    this.price,
    this.location,
    this.isActive = true,
    this.viewCount = 0,
    this.tags = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PostType.other,
      ),
      category: json['category'] ?? '',
      authorName: json['author_name'] ?? '',
      authorContact: json['author_contact'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      price: json['price']?.toDouble(),
      location: json['location'],
      isActive: json['is_active'] ?? true,
      viewCount: json['view_count'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category,
      'author_name': authorName,
      'author_contact': authorContact,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'image_urls': imageUrls,
      'price': price,
      'location': location,
      'is_active': isActive,
      'view_count': viewCount,
      'tags': tags,
    };
  }

  String get typeDisplayName {
    return type.displayName;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Post copyWith({
    String? id,
    String? title,
    String? description,
    PostType? type,
    String? category,
    String? authorName,
    String? authorContact,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? imageUrls,
    double? price,
    String? location,
    bool? isActive,
    int? viewCount,
    List<String>? tags,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      authorName: authorName ?? this.authorName,
      authorContact: authorContact ?? this.authorContact,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      imageUrls: imageUrls ?? this.imageUrls,
      price: price ?? this.price,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      tags: tags ?? this.tags,
    );
  }
}