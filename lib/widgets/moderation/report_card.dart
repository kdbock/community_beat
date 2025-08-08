// lib/widgets/moderation/report_card.dart

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/report.dart';
import '../../services/moderation_service.dart';
import 'moderation_action_dialog.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onStatusChanged;

  const ReportCard({
    super.key,
    required this.report,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and content type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: report.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: report.status.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        report.status.icon,
                        size: 14,
                        color: report.status.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.status.displayName,
                        style: TextStyle(
                          color: report.status.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        report.contentType.icon,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.contentType.displayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  timeago.format(report.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Report type and reason
            Row(
              children: [
                Icon(
                  report.reportType.icon,
                  size: 20,
                  color: Colors.red[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportType.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (report.reason.isNotEmpty)
                        Text(
                          report.reason,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Additional details
            if (report.additionalDetails != null && report.additionalDetails!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.additionalDetails!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            
            // Content snapshot
            if (report.contentSnapshot.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.content_copy,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reported Content:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (report.contentSnapshot['title'] != null) ...[
                      Text(
                        'Title: ${report.contentSnapshot['title']}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (report.contentSnapshot['content'] != null)
                      Text(
                        report.contentSnapshot['content'],
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (report.contentSnapshot['author_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'By: ${report.contentSnapshot['author_name']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Reporter info
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Reported by: ${report.reporterName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (report.reportedUserName != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.account_circle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Content by: ${report.reportedUserName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            
            // Review info (if reviewed)
            if (report.reviewedAt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reviewed by ${report.reviewerName ?? 'Unknown'} • ${timeago.format(report.reviewedAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (report.moderationAction != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Action: ${report.moderationAction}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                    if (report.moderationNotes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Notes: ${report.moderationNotes}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Action buttons
            if (report.status == ReportStatus.pending || report.status == ReportStatus.underReview) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (report.status == ReportStatus.pending)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(context, ReportStatus.underReview),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Start Review'),
                      ),
                    ),
                  if (report.status == ReportStatus.pending)
                    const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showModerationDialog(context),
                      icon: const Icon(Icons.gavel, size: 16),
                      label: const Text('Take Action'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(context, ReportStatus.dismissed),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, ReportStatus status) async {
    try {
      await ModerationService.updateReportStatus(
        reportId: report.id,
        status: status,
        moderationAction: status == ReportStatus.dismissed ? 'Dismissed' : null,
        moderationNotes: status == ReportStatus.dismissed ? 'Report dismissed by moderator' : null,
      );
      
      onStatusChanged?.call();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report ${status.displayName.toLowerCase()}'),
            backgroundColor: status.color,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showModerationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ModerationActionDialog(
        report: report,
        onActionTaken: onStatusChanged,
      ),
    );
  }
}