// lib/services/rsvp_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rsvp.dart';

class RSVPService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get RSVP status for current user and specific event
  static Future<RSVP?> getUserRSVP(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection('rsvps')
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return RSVP.fromJson({
        'id': querySnapshot.docs.first.id,
        ...querySnapshot.docs.first.data(),
      });
    } catch (e) {
      throw Exception('Failed to get RSVP status: $e');
    }
  }

  /// Create or update RSVP for current user
  static Future<RSVP> createOrUpdateRSVP({
    required String eventId,
    required RSVPStatus status,
    int? partySize,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if RSVP already exists
      final existingRSVP = await getUserRSVP(eventId);
      
      final rsvpData = {
        'event_id': eventId,
        'user_id': user.uid,
        'user_name': user.displayName ?? user.email ?? 'Anonymous',
        'user_email': user.email ?? '',
        'rsvp_date': DateTime.now().toIso8601String(),
        'status': status.name,
        'party_size': partySize,
        'notes': notes,
      };

      if (existingRSVP != null) {
        // Update existing RSVP
        await _firestore
            .collection('rsvps')
            .doc(existingRSVP.id)
            .update(rsvpData);
        
        return RSVP.fromJson({
          'id': existingRSVP.id,
          ...rsvpData,
        });
      } else {
        // Create new RSVP
        final docRef = await _firestore
            .collection('rsvps')
            .add(rsvpData);
        
        return RSVP.fromJson({
          'id': docRef.id,
          ...rsvpData,
        });
      }
    } catch (e) {
      throw Exception('Failed to create/update RSVP: $e');
    }
  }

  /// Delete RSVP for current user
  static Future<void> deleteRSVP(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _firestore
          .collection('rsvps')
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete RSVP: $e');
    }
  }

  /// Get all RSVPs for a specific event
  static Future<List<RSVP>> getEventRSVPs(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('rsvps')
          .where('event_id', isEqualTo: eventId)
          .orderBy('rsvp_date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RSVP.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get event RSVPs: $e');
    }
  }

  /// Get RSVP count by status for a specific event
  static Future<Map<RSVPStatus, int>> getEventRSVPCounts(String eventId) async {
    try {
      final rsvps = await getEventRSVPs(eventId);
      final counts = <RSVPStatus, int>{};
      
      for (final status in RSVPStatus.values) {
        counts[status] = rsvps.where((rsvp) => rsvp.status == status).length;
      }
      
      return counts;
    } catch (e) {
      throw Exception('Failed to get RSVP counts: $e');
    }
  }

  /// Get total attendee count for an event (going + maybe)
  static Future<int> getEventAttendeeCount(String eventId) async {
    try {
      final counts = await getEventRSVPCounts(eventId);
      return (counts[RSVPStatus.going] ?? 0) + (counts[RSVPStatus.maybe] ?? 0);
    } catch (e) {
      throw Exception('Failed to get attendee count: $e');
    }
  }

  /// Get all RSVPs for current user
  static Future<List<RSVP>> getUserRSVPs() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('rsvps')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('rsvp_date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RSVP.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user RSVPs: $e');
    }
  }

  /// Stream of RSVPs for a specific event (real-time updates)
  static Stream<List<RSVP>> streamEventRSVPs(String eventId) {
    return _firestore
        .collection('rsvps')
        .where('event_id', isEqualTo: eventId)
        .orderBy('rsvp_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RSVP.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Stream of RSVP status for current user and specific event
  static Stream<RSVP?> streamUserRSVP(String eventId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('rsvps')
        .where('event_id', isEqualTo: eventId)
        .where('user_id', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return RSVP.fromJson({
            'id': snapshot.docs.first.id,
            ...snapshot.docs.first.data(),
          });
        });
  }
}