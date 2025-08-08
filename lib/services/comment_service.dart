// lib/services/comment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';

class CommentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a comment to content (post, event, etc.)
  static Future<Comment> addComment({
    required String contentId,
    required ContentType contentType,
    required String content,
    String? parentCommentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final commentData = {
        'content_id': contentId,
        'content_type': contentType.name,
        'user_id': user.uid,
        'user_name': user.displayName ?? user.email ?? 'Anonymous',
        'user_email': user.email ?? '',
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'parent_comment_id': parentCommentId,
        'likes': <String>[],
        'is_edited': false,
        'is_deleted': false,
        'is_moderated': false,
      };

      final docRef = await _firestore
          .collection('comments')
          .add(commentData);

      // Update comment count on the parent content
      await _updateCommentCount(contentId, contentType, 1);

      return Comment.fromJson({
        'id': docRef.id,
        ...commentData,
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for specific content
  static Future<List<Comment>> getComments({
    required String contentId,
    required ContentType contentType,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('content_id', isEqualTo: contentId)
          .where('content_type', isEqualTo: contentType.name)
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: false)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Comment.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  /// Get comment threads (organized with replies)
  static Future<List<CommentThread>> getCommentThreads({
    required String contentId,
    required ContentType contentType,
    int limit = 50,
  }) async {
    try {
      final comments = await getComments(
        contentId: contentId,
        contentType: contentType,
        limit: limit,
      );

      // Separate top-level comments from replies
      final topLevelComments = comments
          .where((comment) => comment.parentCommentId == null)
          .toList();

      // Create threads with nested replies
      return topLevelComments
          .map((comment) => CommentThread.fromComment(comment, comments))
          .toList();
    } catch (e) {
      throw Exception('Failed to get comment threads: $e');
    }
  }

  /// Update a comment
  static Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // First, verify the user owns this comment
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      if (commentData['user_id'] != user.uid) {
        throw Exception('Not authorized to edit this comment');
      }

      final updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
        'is_edited': true,
      };

      await _firestore
          .collection('comments')
          .doc(commentId)
          .update(updateData);

      return Comment.fromJson({
        'id': commentId,
        ...commentData,
        ...updateData,
      });
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  /// Delete a comment
  static Future<void> deleteComment(String commentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get comment to verify ownership and get content info
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      if (commentData['user_id'] != user.uid) {
        throw Exception('Not authorized to delete this comment');
      }

      // Soft delete - mark as deleted instead of removing
      await _firestore
          .collection('comments')
          .doc(commentId)
          .update({
            'is_deleted': true,
            'content': '[Comment deleted]',
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Update comment count on parent content
      final contentType = ContentType.values.firstWhere(
        (type) => type.name == commentData['content_type'],
      );
      await _updateCommentCount(
        commentData['content_id'],
        contentType,
        -1,
      );
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Like/unlike a comment
  static Future<Comment> toggleCommentLike(String commentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      final likes = List<String>.from(commentData['likes'] ?? []);
      
      if (likes.contains(user.uid)) {
        // Unlike
        likes.remove(user.uid);
      } else {
        // Like
        likes.add(user.uid);
      }

      await _firestore
          .collection('comments')
          .doc(commentId)
          .update({'likes': likes});

      return Comment.fromJson({
        'id': commentId,
        ...commentData,
        'likes': likes,
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  /// Get comment count for content
  static Future<int> getCommentCount({
    required String contentId,
    required ContentType contentType,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('content_id', isEqualTo: contentId)
          .where('content_type', isEqualTo: contentType.name)
          .where('is_deleted', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream comments for real-time updates
  static Stream<List<Comment>> streamComments({
    required String contentId,
    required ContentType contentType,
    int limit = 50,
  }) {
    return _firestore
        .collection('comments')
        .where('content_id', isEqualTo: contentId)
        .where('content_type', isEqualTo: contentType.name)
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Stream comment threads for real-time updates
  static Stream<List<CommentThread>> streamCommentThreads({
    required String contentId,
    required ContentType contentType,
    int limit = 50,
  }) {
    return streamComments(
      contentId: contentId,
      contentType: contentType,
      limit: limit,
    ).map((comments) {
      final topLevelComments = comments
          .where((comment) => comment.parentCommentId == null)
          .toList();

      return topLevelComments
          .map((comment) => CommentThread.fromComment(comment, comments))
          .toList();
    });
  }

  /// Report a comment for moderation
  static Future<void> reportComment({
    required String commentId,
    required String reason,
    String? additionalInfo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('comment_reports').add({
        'comment_id': commentId,
        'reported_by': user.uid,
        'reporter_name': user.displayName ?? user.email ?? 'Anonymous',
        'reason': reason,
        'additional_info': additionalInfo,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report comment: $e');
    }
  }

  /// Get user's comments
  static Future<List<Comment>> getUserComments({
    String? userId,
    int limit = 50,
  }) async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    
    if (targetUserId == null) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('user_id', isEqualTo: targetUserId)
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Comment.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user comments: $e');
    }
  }

  /// Update comment count on parent content
  static Future<void> _updateCommentCount(
    String contentId,
    ContentType contentType,
    int increment,
  ) async {
    try {
      final contentRef = _firestore
          .collection(contentType.collectionName)
          .doc(contentId);

      await _firestore.runTransaction((transaction) async {
        final contentDoc = await transaction.get(contentRef);
        if (contentDoc.exists) {
          final currentCount = contentDoc.data()?['comment_count'] ?? 0;
          final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
          transaction.update(contentRef, {'comment_count': newCount});
        }
      });
    } catch (e) {
      // Silently fail - comment count is not critical
    }
  }

  /// Moderate comment (admin/moderator only)
  static Future<void> moderateComment({
    required String commentId,
    required bool isModerated,
    String? moderationReason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('comments')
          .doc(commentId)
          .update({
            'is_moderated': isModerated,
            'moderation_reason': moderationReason,
            'moderated_at': DateTime.now().toIso8601String(),
            'moderated_by': user.uid,
          });
    } catch (e) {
      throw Exception('Failed to moderate comment: $e');
    }
  }
}