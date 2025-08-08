// lib/services/reaction_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reaction.dart';
import '../models/comment.dart';

class ReactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add or update a reaction to content
  static Future<Reaction> addReaction({
    required String contentId,
    required ContentType contentType,
    required ReactionType reactionType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if user already has a reaction on this content
      final existingReaction = await getUserReaction(contentId, contentType);
      
      final reactionData = {
        'content_id': contentId,
        'content_type': contentType.name,
        'user_id': user.uid,
        'user_name': user.displayName ?? user.email ?? 'Anonymous',
        'reaction_type': reactionType.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (existingReaction != null) {
        // Update existing reaction
        await _firestore
            .collection('reactions')
            .doc(existingReaction.id)
            .update(reactionData);
        
        return Reaction.fromJson({
          'id': existingReaction.id,
          ...reactionData,
        });
      } else {
        // Create new reaction
        final docRef = await _firestore
            .collection('reactions')
            .add(reactionData);
        
        // Update reaction count on parent content
        await _updateReactionCount(contentId, contentType, 1);
        
        return Reaction.fromJson({
          'id': docRef.id,
          ...reactionData,
        });
      }
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  /// Remove user's reaction from content
  static Future<void> removeReaction({
    required String contentId,
    required ContentType contentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _firestore
          .collection('reactions')
          .where('content_id', isEqualTo: contentId)
          .where('content_type', isEqualTo: contentType.name)
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Update reaction count on parent content
      if (querySnapshot.docs.isNotEmpty) {
        await _updateReactionCount(contentId, contentType, -1);
      }
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  /// Toggle reaction (add if not exists, remove if exists, or change type)
  static Future<Reaction?> toggleReaction({
    required String contentId,
    required ContentType contentType,
    required ReactionType reactionType,
  }) async {
    final existingReaction = await getUserReaction(contentId, contentType);
    
    if (existingReaction == null) {
      // Add new reaction
      return await addReaction(
        contentId: contentId,
        contentType: contentType,
        reactionType: reactionType,
      );
    } else if (existingReaction.reactionType == reactionType) {
      // Remove existing reaction (same type)
      await removeReaction(
        contentId: contentId,
        contentType: contentType,
      );
      return null;
    } else {
      // Change reaction type
      return await addReaction(
        contentId: contentId,
        contentType: contentType,
        reactionType: reactionType,
      );
    }
  }

  /// Get user's reaction for specific content
  static Future<Reaction?> getUserReaction(
    String contentId,
    ContentType contentType,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection('reactions')
          .where('content_id', isEqualTo: contentId)
          .where('content_type', isEqualTo: contentType.name)
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return Reaction.fromJson({
        'id': querySnapshot.docs.first.id,
        ...querySnapshot.docs.first.data(),
      });
    } catch (e) {
      return null;
    }
  }

  /// Get all reactions for specific content
  static Future<List<Reaction>> getReactions({
    required String contentId,
    required ContentType contentType,
    int limit = 100,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('reactions')
          .where('content_id', isEqualTo: contentId)
          .where('content_type', isEqualTo: contentType.name)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Reaction.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reactions: $e');
    }
  }

  /// Get reaction summary for content
  static Future<ReactionSummary> getReactionSummary({
    required String contentId,
    required ContentType contentType,
  }) async {
    try {
      final reactions = await getReactions(
        contentId: contentId,
        contentType: contentType,
      );
      
      final user = _auth.currentUser;
      return ReactionSummary.fromReactions(
        reactions,
        currentUserId: user?.uid,
      );
    } catch (e) {
      throw Exception('Failed to get reaction summary: $e');
    }
  }

  /// Get reactions by type for specific content
  static Future<List<Reaction>> getReactionsByType({
    required String contentId,
    required ContentType contentType,
    required ReactionType reactionType,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('reactions')
          .where('content_id', isEqualTo: contentId)
          .where('content_type', isEqualTo: contentType.name)
          .where('reaction_type', isEqualTo: reactionType.name)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Reaction.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reactions by type: $e');
    }
  }

  /// Stream reactions for real-time updates
  static Stream<List<Reaction>> streamReactions({
    required String contentId,
    required ContentType contentType,
    int limit = 100,
  }) {
    return _firestore
        .collection('reactions')
        .where('content_id', isEqualTo: contentId)
        .where('content_type', isEqualTo: contentType.name)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reaction.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Stream reaction summary for real-time updates
  static Stream<ReactionSummary> streamReactionSummary({
    required String contentId,
    required ContentType contentType,
  }) {
    return streamReactions(
      contentId: contentId,
      contentType: contentType,
    ).map((reactions) {
      final user = _auth.currentUser;
      return ReactionSummary.fromReactions(
        reactions,
        currentUserId: user?.uid,
      );
    });
  }

  /// Get user's all reactions
  static Future<List<Reaction>> getUserReactions({
    String? userId,
    int limit = 50,
  }) async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    
    if (targetUserId == null) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _firestore
          .collection('reactions')
          .where('user_id', isEqualTo: targetUserId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Reaction.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reactions: $e');
    }
  }

  /// Get reaction statistics for content
  static Future<Map<String, dynamic>> getReactionStats({
    required String contentId,
    required ContentType contentType,
  }) async {
    try {
      final reactions = await getReactions(
        contentId: contentId,
        contentType: contentType,
      );

      final stats = <String, dynamic>{
        'total_reactions': reactions.length,
        'reaction_counts': <String, int>{},
        'unique_users': <String>{},
        'most_popular_reaction': null,
      };

      for (final reaction in reactions) {
        // Count by reaction type
        final typeName = reaction.reactionType.name;
        stats['reaction_counts'][typeName] = 
            (stats['reaction_counts'][typeName] ?? 0) + 1;
        
        // Track unique users
        (stats['unique_users'] as Set<String>).add(reaction.userId);
      }

      // Find most popular reaction
      if ((stats['reaction_counts'] as Map<String, int>).isNotEmpty) {
        final mostPopular = (stats['reaction_counts'] as Map<String, int>)
            .entries
            .reduce((a, b) => a.value > b.value ? a : b);
        stats['most_popular_reaction'] = mostPopular.key;
      }

      stats['unique_users'] = (stats['unique_users'] as Set<String>).length;

      return stats;
    } catch (e) {
      throw Exception('Failed to get reaction stats: $e');
    }
  }

  /// Update reaction count on parent content
  static Future<void> _updateReactionCount(
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
          final currentCount = contentDoc.data()?['reaction_count'] ?? 0;
          final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
          transaction.update(contentRef, {'reaction_count': newCount});
        }
      });
    } catch (e) {
      // Silently fail - reaction count is not critical
    }
  }

  /// Get trending content based on reactions
  static Future<List<Map<String, dynamic>>> getTrendingContent({
    required ContentType contentType,
    int limit = 10,
    Duration timeWindow = const Duration(days: 7),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(timeWindow);
      
      final querySnapshot = await _firestore
          .collection('reactions')
          .where('content_type', isEqualTo: contentType.name)
          .where('created_at', isGreaterThan: cutoffDate.toIso8601String())
          .get();

      // Group reactions by content ID and count
      final contentReactionCounts = <String, int>{};
      for (final doc in querySnapshot.docs) {
        final contentId = doc.data()['content_id'] as String;
        contentReactionCounts[contentId] = 
            (contentReactionCounts[contentId] ?? 0) + 1;
      }

      // Sort by reaction count and return top content IDs
      final sortedContent = contentReactionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedContent
          .take(limit)
          .map((entry) => {
                'content_id': entry.key,
                'reaction_count': entry.value,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get trending content: $e');
    }
  }
}