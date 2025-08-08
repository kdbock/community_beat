// lib/services/moderation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report.dart';

class ModerationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a report for content or user
  static Future<String> submitReport({
    required String reportedContentId,
    required ReportedContentType contentType,
    required ReportType reportType,
    required String reason,
    String? additionalDetails,
    String? reportedUserId,
    String? reportedUserName,
    Map<String, dynamic>? contentSnapshot,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get reporter info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final reporterName = userData?['display_name'] ?? 'Unknown User';

      // Create report
      final reportRef = _firestore.collection('reports').doc();
      final report = Report(
        id: reportRef.id,
        reporterId: user.uid,
        reporterName: reporterName,
        reportedContentId: reportedContentId,
        contentType: contentType,
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        reportType: reportType,
        reason: reason,
        additionalDetails: additionalDetails,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
        contentSnapshot: contentSnapshot ?? {},
      );

      await reportRef.set(report.toJson());

      // Update content with report flag if applicable
      if (contentType != ReportedContentType.user) {
        await _flagContent(contentType, reportedContentId);
      }

      // Create notification for moderators
      await _notifyModerators(report);

      return reportRef.id;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get all reports (admin/moderator only)
  static Stream<List<Report>> getReports({
    ReportStatus? status,
    ReportedContentType? contentType,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('reports')
        .orderBy('created_at', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }

    if (contentType != null) {
      query = query.where('content_type', isEqualTo: contentType.toString().split('.').last);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Report.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  /// Get reports for specific content
  static Stream<List<Report>> getReportsForContent({
    required String contentId,
    required ReportedContentType contentType,
  }) {
    return _firestore
        .collection('reports')
        .where('reported_content_id', isEqualTo: contentId)
        .where('content_type', isEqualTo: contentType.toString().split('.').last)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Report.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  /// Update report status (admin/moderator only)
  static Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? moderationAction,
    String? moderationNotes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get reviewer info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final reviewerName = userData?['display_name'] ?? 'Unknown Moderator';

      await _firestore.collection('reports').doc(reportId).update({
        'status': status.toString().split('.').last,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': user.uid,
        'reviewer_name': reviewerName,
        'moderation_action': moderationAction,
        'moderation_notes': moderationNotes,
      });
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Take moderation action on content
  static Future<void> moderateContent({
    required String contentId,
    required ReportedContentType contentType,
    required String action, // 'hide', 'delete', 'warn', 'no_action'
    String? reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final collectionName = contentType.collectionName;
      final contentRef = _firestore.collection(collectionName).doc(contentId);

      switch (action) {
        case 'hide':
          await contentRef.update({
            'is_hidden': true,
            'hidden_at': DateTime.now().toIso8601String(),
            'hidden_by': user.uid,
            'hidden_reason': reason,
          });
          break;
        case 'delete':
          await contentRef.update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user.uid,
            'deletion_reason': reason,
          });
          break;
        case 'warn':
          await contentRef.update({
            'has_warning': true,
            'warning_message': reason,
            'warned_at': DateTime.now().toIso8601String(),
            'warned_by': user.uid,
          });
          break;
        case 'no_action':
          // Just update the moderation log
          await contentRef.update({
            'moderation_reviewed': true,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': user.uid,
          });
          break;
      }

      // Log moderation action
      await _logModerationAction(contentId, contentType, action, reason);
    } catch (e) {
      throw Exception('Failed to moderate content: $e');
    }
  }

  /// Suspend or ban user (admin only)
  static Future<void> moderateUser({
    required String userId,
    required String action, // 'warn', 'suspend', 'ban'
    String? reason,
    DateTime? suspensionEnd,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final updates = <String, dynamic>{
        'moderation_action': action,
        'moderation_reason': reason,
        'moderated_at': DateTime.now().toIso8601String(),
        'moderated_by': user.uid,
      };

      switch (action) {
        case 'warn':
          updates['warning_count'] = FieldValue.increment(1);
          break;
        case 'suspend':
          updates['is_suspended'] = true;
          updates['suspension_end'] = suspensionEnd?.toIso8601String();
          break;
        case 'ban':
          updates['is_banned'] = true;
          updates['is_active'] = false;
          break;
      }

      await userRef.update(updates);

      // Log user moderation action
      await _logUserModerationAction(userId, action, reason);
    } catch (e) {
      throw Exception('Failed to moderate user: $e');
    }
  }

  /// Get moderation statistics
  static Future<Map<String, dynamic>> getModerationStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get report counts
      final totalReports = await _firestore.collection('reports').count().get();
      final pendingReports = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      
      final todayReports = await _firestore
          .collection('reports')
          .where('created_at', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .count()
          .get();

      final weekReports = await _firestore
          .collection('reports')
          .where('created_at', isGreaterThanOrEqualTo: startOfWeek.toIso8601String())
          .count()
          .get();

      final monthReports = await _firestore
          .collection('reports')
          .where('created_at', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .count()
          .get();

      // Get report types breakdown
      final reportTypes = <String, int>{};
      for (final type in ReportType.values) {
        final count = await _firestore
            .collection('reports')
            .where('report_type', isEqualTo: type.toString().split('.').last)
            .count()
            .get();
        reportTypes[type.displayName] = count.count ?? 0;
      }

      return {
        'total_reports': totalReports.count ?? 0,
        'pending_reports': pendingReports.count ?? 0,
        'today_reports': todayReports.count ?? 0,
        'week_reports': weekReports.count ?? 0,
        'month_reports': monthReports.count ?? 0,
        'report_types': reportTypes,
      };
    } catch (e) {
      throw Exception('Failed to get moderation stats: $e');
    }
  }

  /// Check if user can moderate content
  static Future<bool> canModerate() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final role = userData?['role'] ?? 'resident';
      return role == 'admin' || role == 'moderator';
    } catch (e) {
      return false;
    }
  }

  /// Get content snapshot for reporting
  static Future<Map<String, dynamic>> getContentSnapshot({
    required String contentId,
    required ReportedContentType contentType,
  }) async {
    try {
      final doc = await _firestore
          .collection(contentType.collectionName)
          .doc(contentId)
          .get();
      
      if (!doc.exists) return {};
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Return relevant fields for the snapshot
      return {
        'title': data['title'] ?? data['content'] ?? '',
        'content': data['content'] ?? data['description'] ?? '',
        'author_id': data['author_id'] ?? data['user_id'] ?? '',
        'author_name': data['author_name'] ?? data['user_name'] ?? '',
        'created_at': data['created_at'],
        'type': contentType.displayName,
      };
    } catch (e) {
      return {};
    }
  }

  // Private helper methods

  static Future<void> _flagContent(ReportedContentType contentType, String contentId) async {
    try {
      await _firestore
          .collection(contentType.collectionName)
          .doc(contentId)
          .update({
            'is_reported': true,
            'report_count': FieldValue.increment(1),
            'last_reported_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Silently fail - flagging is not critical
    }
  }

  static Future<void> _notifyModerators(Report report) async {
    try {
      // Get all moderators and admins
      final moderators = await _firestore
          .collection('users')
          .where('role', whereIn: ['admin', 'moderator'])
          .get();

      // Create notifications for each moderator
      for (final moderatorDoc in moderators.docs) {
        await _firestore.collection('notifications').add({
          'user_id': moderatorDoc.id,
          'title': 'New Content Report',
          'body': 'A ${report.contentType.displayName.toLowerCase()} has been reported for ${report.reportType.displayName.toLowerCase()}',
          'type': 'moderation',
          'data': {
            'report_id': report.id,
            'content_type': report.contentType.toString().split('.').last,
            'report_type': report.reportType.toString().split('.').last,
          },
          'created_at': DateTime.now().toIso8601String(),
          'is_read': false,
        });
      }
    } catch (e) {
      // Silently fail - notifications are not critical
    }
  }

  static Future<void> _logModerationAction(
    String contentId,
    ReportedContentType contentType,
    String action,
    String? reason,
  ) async {
    try {
      await _firestore.collection('moderation_log').add({
        'content_id': contentId,
        'content_type': contentType.toString().split('.').last,
        'action': action,
        'reason': reason,
        'moderator_id': _auth.currentUser?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - logging is not critical
    }
  }

  static Future<void> _logUserModerationAction(
    String userId,
    String action,
    String? reason,
  ) async {
    try {
      await _firestore.collection('user_moderation_log').add({
        'user_id': userId,
        'action': action,
        'reason': reason,
        'moderator_id': _auth.currentUser?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - logging is not critical
    }
  }
}