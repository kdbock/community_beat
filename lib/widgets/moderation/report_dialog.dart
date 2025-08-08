// lib/widgets/moderation/report_dialog.dart

import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/moderation_service.dart';

class ReportDialog extends StatefulWidget {
  final String contentId;
  final ReportedContentType contentType;
  final String? reportedUserId;
  final String? reportedUserName;
  final Map<String, dynamic>? contentSnapshot;

  const ReportDialog({
    super.key,
    required this.contentId,
    required this.contentType,
    this.reportedUserId,
    this.reportedUserName,
    this.contentSnapshot,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportType? _selectedReportType;
  final _reasonController = TextEditingController();
  final _additionalDetailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.report_problem,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text('Report ${widget.contentType.displayName}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us understand what\'s wrong with this ${widget.contentType.displayName.toLowerCase()}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Report Type Selection
            Text(
              'What\'s the issue?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...ReportType.values.map((type) => RadioListTile<ReportType>(
              title: Row(
                children: [
                  Icon(type.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(type.displayName)),
                ],
              ),
              subtitle: Text(
                type.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: type,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value;
                  if (value != null) {
                    _reasonController.text = value.displayName;
                  }
                });
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 16),
            
            // Additional Details
            Text(
              'Additional details (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _additionalDetailsController,
              decoration: const InputDecoration(
                hintText: 'Provide more context about this report...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedReportType == null
              ? null
              : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReportType == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get content snapshot if not provided
      Map<String, dynamic> contentSnapshot = widget.contentSnapshot ?? {};
      if (contentSnapshot.isEmpty) {
        contentSnapshot = await ModerationService.getContentSnapshot(
          contentId: widget.contentId,
          contentType: widget.contentType,
        );
      }

      await ModerationService.submitReport(
        reportedContentId: widget.contentId,
        contentType: widget.contentType,
        reportType: _selectedReportType!,
        reason: _reasonController.text.trim(),
        additionalDetails: _additionalDetailsController.text.trim().isEmpty
            ? null
            : _additionalDetailsController.text.trim(),
        reportedUserId: widget.reportedUserId,
        reportedUserName: widget.reportedUserName,
        contentSnapshot: contentSnapshot,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Report submitted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to submit report: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

/// Helper function to show report dialog
Future<void> showReportDialog({
  required BuildContext context,
  required String contentId,
  required ReportedContentType contentType,
  String? reportedUserId,
  String? reportedUserName,
  Map<String, dynamic>? contentSnapshot,
}) {
  return showDialog(
    context: context,
    builder: (context) => ReportDialog(
      contentId: contentId,
      contentType: contentType,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      contentSnapshot: contentSnapshot,
    ),
  );
}