// lib/services/event_feedback_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_feedback.dart';

class EventFeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit feedback for an event
  static Future<EventFeedback> submitFeedback({
    required String eventId,
    required int rating,
    String? comment,
    List<String> tags = const [],
    bool isAnonymous = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final feedbackData = {
        'event_id': eventId,
        'user_id': user.uid,
        'user_name': isAnonymous ? 'Anonymous' : (user.displayName ?? user.email ?? 'Anonymous'),
        'user_email': isAnonymous ? '' : (user.email ?? ''),
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
        'tags': tags,
        'is_anonymous': isAnonymous,
      };

      final docRef = await _firestore
          .collection('event_feedback')
          .add(feedbackData);

      return EventFeedback.fromJson({
        'id': docRef.id,
        ...feedbackData,
      });
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Get user's feedback for a specific event
  static Future<EventFeedback?> getUserFeedback(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection('event_feedback')
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return EventFeedback.fromJson({
        'id': querySnapshot.docs.first.id,
        ...querySnapshot.docs.first.data(),
      });
    } catch (e) {
      throw Exception('Failed to get user feedback: $e');
    }
  }

  /// Get all feedback for an event
  static Future<List<EventFeedback>> getEventFeedback(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('event_feedback')
          .where('event_id', isEqualTo: eventId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventFeedback.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get event feedback: $e');
    }
  }

  /// Get event rating summary
  static Future<EventRating> getEventRating(String eventId) async {
    try {
      final feedbacks = await getEventFeedback(eventId);
      return EventRating.fromFeedbackList(feedbacks);
    } catch (e) {
      throw Exception('Failed to get event rating: $e');
    }
  }

  /// Update existing feedback
  static Future<EventFeedback> updateFeedback({
    required String feedbackId,
    required int rating,
    String? comment,
    List<String> tags = const [],
    bool isAnonymous = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final updateData = {
        'rating': rating,
        'comment': comment,
        'tags': tags,
        'is_anonymous': isAnonymous,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('event_feedback')
          .doc(feedbackId)
          .update(updateData);

      // Get updated feedback
      final doc = await _firestore
          .collection('event_feedback')
          .doc(feedbackId)
          .get();

      return EventFeedback.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to update feedback: $e');
    }
  }

  /// Delete feedback
  static Future<void> deleteFeedback(String feedbackId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('event_feedback')
          .doc(feedbackId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }

  /// Get feedback statistics for an organizer's events
  static Future<Map<String, dynamic>> getOrganizerFeedbackStats(String organizerId) async {
    try {
      // This would require a more complex query joining events and feedback
      // For now, return mock data structure
      return {
        'total_events': 0,
        'total_feedback': 0,
        'average_rating': 0.0,
        'rating_distribution': <int, int>{},
        'common_tags': <String>[],
      };
    } catch (e) {
      throw Exception('Failed to get organizer feedback stats: $e');
    }
  }

  /// Stream feedback for real-time updates
  static Stream<List<EventFeedback>> streamEventFeedback(String eventId) {
    return _firestore
        .collection('event_feedback')
        .where('event_id', isEqualTo: eventId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventFeedback.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Check if user can leave feedback (must have RSVP'd and event must be past)
  static Future<bool> canUserLeaveFeedback(String eventId, DateTime eventDate) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check if event has passed
    if (DateTime.now().isBefore(eventDate)) return false;

    try {
      // Check if user RSVP'd to the event
      final rsvpQuery = await _firestore
          .collection('rsvps')
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'going')
          .limit(1)
          .get();

      return rsvpQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get recent feedback across all events (for admin/moderation)
  static Future<List<EventFeedback>> getRecentFeedback({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('event_feedback')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => EventFeedback.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent feedback: $e');
    }
  }
}