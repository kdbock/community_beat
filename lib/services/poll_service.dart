// lib/services/poll_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poll.dart';

class PollService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _pollsCollection => _firestore.collection('polls');
  static CollectionReference get _votesCollection => _firestore.collection('poll_votes');

  // Create a new poll
  static Future<String> createPoll(Poll poll) async {
    try {
      final docRef = await _pollsCollection.add(poll.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create poll: $e');
    }
  }

  // Get all active polls
  static Future<List<Poll>> getActivePolls({
    PollCategory? category,
    int limit = 20,
  }) async {
    try {
      Query query = _pollsCollection
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch polls: $e');
    }
  }

  // Get polls stream for real-time updates
  static Stream<List<Poll>> getPollsStream({
    PollCategory? category,
    int limit = 20,
  }) {
    try {
      Query query = _pollsCollection
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList());
    } catch (e) {
      throw Exception('Failed to get polls stream: $e');
    }
  }

  // Get a specific poll by ID
  static Future<Poll?> getPoll(String pollId) async {
    try {
      final doc = await _pollsCollection.doc(pollId).get();
      if (doc.exists) {
        return Poll.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch poll: $e');
    }
  }

  // Vote on a poll
  static Future<void> voteOnPoll({
    required String pollId,
    required List<String> selectedOptionIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if user has already voted
      final existingVote = await _votesCollection
          .where('poll_id', isEqualTo: pollId)
          .where('user_id', isEqualTo: user.uid)
          .get();

      // Use a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        // Get current poll data
        final pollDoc = await transaction.get(_pollsCollection.doc(pollId));
        if (!pollDoc.exists) throw Exception('Poll not found');

        final poll = Poll.fromFirestore(pollDoc);
        if (!poll.canVote) throw Exception('Poll is not available for voting');

        // If user has already voted and multiple votes not allowed, update existing vote
        if (existingVote.docs.isNotEmpty && !poll.allowMultipleVotes) {
          final existingVoteDoc = existingVote.docs.first;
          final existingVoteData = PollVote.fromFirestore(existingVoteDoc);

          // Remove old votes from poll options
          final updatedOptions = poll.options.map((option) {
            if (existingVoteData.selectedOptionIds.contains(option.id)) {
              return option.copyWith(voteCount: option.voteCount - 1);
            }
            return option;
          }).toList();

          // Add new votes to poll options
          final finalOptions = updatedOptions.map((option) {
            if (selectedOptionIds.contains(option.id)) {
              return option.copyWith(voteCount: option.voteCount + 1);
            }
            return option;
          }).toList();

          // Update poll with new vote counts
          transaction.update(_pollsCollection.doc(pollId), {
            'options': finalOptions.map((o) => o.toFirestore()).toList(),
          });

          // Update the vote record
          transaction.update(existingVoteDoc.reference, {
            'selected_option_ids': selectedOptionIds,
            'voted_at': Timestamp.now(),
          });
        } else {
          // Create new vote
          final vote = PollVote(
            id: '',
            pollId: pollId,
            userId: user.uid,
            selectedOptionIds: selectedOptionIds,
            votedAt: DateTime.now(),
            userDisplayName: user.displayName,
          );

          // Add votes to poll options
          final updatedOptions = poll.options.map((option) {
            if (selectedOptionIds.contains(option.id)) {
              return option.copyWith(voteCount: option.voteCount + 1);
            }
            return option;
          }).toList();

          // Update poll with new vote counts
          transaction.update(_pollsCollection.doc(pollId), {
            'options': updatedOptions.map((o) => o.toFirestore()).toList(),
          });

          // Create vote record
          transaction.set(_votesCollection.doc(), vote.toFirestore());
        }
      });
    } catch (e) {
      throw Exception('Failed to vote on poll: $e');
    }
  }

  // Check if current user has voted on a poll
  static Future<PollVote?> getUserVote(String pollId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _votesCollection
          .where('poll_id', isEqualTo: pollId)
          .where('user_id', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return PollVote.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to check user vote: $e');
    }
  }

  // Get poll results with detailed vote information
  static Future<Map<String, dynamic>> getPollResults(String pollId) async {
    try {
      final poll = await getPoll(pollId);
      if (poll == null) throw Exception('Poll not found');

      final votesSnapshot = await _votesCollection
          .where('poll_id', isEqualTo: pollId)
          .get();

      final votes = votesSnapshot.docs
          .map((doc) => PollVote.fromFirestore(doc))
          .toList();

      return {
        'poll': poll,
        'votes': votes,
        'total_votes': poll.totalVotes,
        'unique_voters': votes.length,
        'winning_options': poll.winningOptions,
      };
    } catch (e) {
      throw Exception('Failed to get poll results: $e');
    }
  }

  // Update poll (only creator or admin can update)
  static Future<void> updatePoll(String pollId, Map<String, dynamic> updates) async {
    try {
      await _pollsCollection.doc(pollId).update(updates);
    } catch (e) {
      throw Exception('Failed to update poll: $e');
    }
  }

  // Close/deactivate a poll
  static Future<void> closePoll(String pollId) async {
    try {
      await _pollsCollection.doc(pollId).update({
        'is_active': false,
      });
    } catch (e) {
      throw Exception('Failed to close poll: $e');
    }
  }

  // Delete a poll (only creator or admin)
  static Future<void> deletePoll(String pollId) async {
    try {
      // Delete all votes for this poll
      final votesSnapshot = await _votesCollection
          .where('poll_id', isEqualTo: pollId)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in votesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the poll
      batch.delete(_pollsCollection.doc(pollId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete poll: $e');
    }
  }

  // Get polls created by current user
  static Future<List<Poll>> getUserPolls() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _pollsCollection
          .where('creator_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user polls: $e');
    }
  }

  // Search polls
  static Future<List<Poll>> searchPolls(String query, {
    PollCategory? category,
    int limit = 20,
  }) async {
    try {
      Query baseQuery = _pollsCollection
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true);

      if (category != null) {
        baseQuery = baseQuery.where('category', isEqualTo: category.name);
      }

      final snapshot = await baseQuery.limit(limit * 2).get(); // Get more to filter

      // Filter by query (simple text search)
      final polls = snapshot.docs
          .map((doc) => Poll.fromFirestore(doc))
          .where((poll) =>
              poll.title.toLowerCase().contains(query.toLowerCase()) ||
              poll.description.toLowerCase().contains(query.toLowerCase()) ||
              poll.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .take(limit)
          .toList();

      return polls;
    } catch (e) {
      throw Exception('Failed to search polls: $e');
    }
  }

  // Get poll statistics
  static Future<Map<String, dynamic>> getPollStatistics() async {
    try {
      final pollsSnapshot = await _pollsCollection.get();
      final votesSnapshot = await _votesCollection.get();

      final polls = pollsSnapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
      final votes = votesSnapshot.docs.map((doc) => PollVote.fromFirestore(doc)).toList();

      final activePolls = polls.where((p) => p.isActive).length;
      final expiredPolls = polls.where((p) => p.isExpired).length;
      final totalVotes = votes.length;

      // Category breakdown
      final categoryBreakdown = <String, int>{};
      for (final poll in polls) {
        categoryBreakdown[poll.category.displayName] = 
            (categoryBreakdown[poll.category.displayName] ?? 0) + 1;
      }

      return {
        'total_polls': polls.length,
        'active_polls': activePolls,
        'expired_polls': expiredPolls,
        'total_votes': totalVotes,
        'category_breakdown': categoryBreakdown,
        'average_votes_per_poll': polls.isEmpty ? 0 : totalVotes / polls.length,
      };
    } catch (e) {
      throw Exception('Failed to get poll statistics: $e');
    }
  }
}