// lib/models/comment.dart

class Comment {
  final String id;
  final String contentId; // ID of the post, event, or other content
  final ContentType contentType; // post, event, service_request, etc.
  final String userId;
  final String userName;
  final String userEmail;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentCommentId; // For nested replies
  final List<String> likes; // User IDs who liked this comment
  final bool isEdited;
  final bool isDeleted;
  final bool isModerated;

  Comment({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
    this.likes = const [],
    this.isEdited = false,
    this.isDeleted = false,
    this.isModerated = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      contentId: json['content_id'] ?? '',
      contentType: ContentType.values.firstWhere(
        (type) => type.name == json['content_type'],
        orElse: () => ContentType.post,
      ),
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      parentCommentId: json['parent_comment_id'],
      likes: List<String>.from(json['likes'] ?? []),
      isEdited: json['is_edited'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      isModerated: json['is_moderated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'content_type': contentType.name,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'parent_comment_id': parentCommentId,
      'likes': likes,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'is_moderated': isModerated,
    };
  }

  Comment copyWith({
    String? id,
    String? contentId,
    ContentType? contentType,
    String? userId,
    String? userName,
    String? userEmail,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
    List<String>? likes,
    bool? isEdited,
    bool? isDeleted,
    bool? isModerated,
  }) {
    return Comment(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likes: likes ?? this.likes,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isModerated: isModerated ?? this.isModerated,
    );
  }

  // Helper methods
  bool get isReply => parentCommentId != null;
  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);
  
  String get displayContent {
    if (isDeleted) return '[Comment deleted]';
    if (isModerated) return '[Comment removed by moderator]';
    return content;
  }

  String get displayUserName {
    if (isDeleted || isModerated) return 'Deleted User';
    return userName;
  }
}

enum ContentType {
  post,
  event,
  serviceRequest,
  business,
  news,
}

extension ContentTypeExtension on ContentType {
  String get displayName {
    switch (this) {
      case ContentType.post:
        return 'Post';
      case ContentType.event:
        return 'Event';
      case ContentType.serviceRequest:
        return 'Service Request';
      case ContentType.business:
        return 'Business';
      case ContentType.news:
        return 'News';
    }
  }

  String get collectionName {
    switch (this) {
      case ContentType.post:
        return 'posts';
      case ContentType.event:
        return 'events';
      case ContentType.serviceRequest:
        return 'service_requests';
      case ContentType.business:
        return 'businesses';
      case ContentType.news:
        return 'news';
    }
  }
}

// Comment thread structure for nested comments
class CommentThread {
  final Comment comment;
  final List<CommentThread> replies;
  final int totalReplies;

  CommentThread({
    required this.comment,
    this.replies = const [],
    this.totalReplies = 0,
  });

  factory CommentThread.fromComment(Comment comment, List<Comment> allComments) {
    final replies = allComments
        .where((c) => c.parentCommentId == comment.id)
        .map((reply) => CommentThread.fromComment(reply, allComments))
        .toList();

    return CommentThread(
      comment: comment,
      replies: replies,
      totalReplies: replies.length,
    );
  }
}