// lib/widgets/moderation/moderation_action_dialog.dart

import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/moderation_service.dart';

class ModerationActionDialog extends StatefulWidget {
  final Report report;
  final VoidCallback? onActionTaken;

  const ModerationActionDialog({
    super.key,
    required this.report,
    this.onActionTaken,
  });

  @override
  State<ModerationActionDialog> createState() => _ModerationActionDialogState();
}

class _ModerationActionDialogState extends State<ModerationActionDialog> {
  String? _selectedAction;
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  final Map<String, ModerationActionInfo> _actions = {
    'no_action': ModerationActionInfo(
      title: 'No Action Required',
      description: 'Report is valid but no action needed',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    ),
    'warn': ModerationActionInfo(
      title: 'Add Warning',
      description: 'Add a warning message to the content',
      icon: Icons.warning_amber,
      color: Colors.orange,
    ),
    'hide': ModerationActionInfo(
      title: 'Hide Content',
      description: 'Hide content from public view',
      icon: Icons.visibility_off,
      color: Colors.blue,
    ),
    'delete': ModerationActionInfo(
      title: 'Delete Content',
      description: 'Permanently remove the content',
      icon: Icons.delete_forever,
      color: Colors.red,
    ),
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.gavel,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          const Text('Moderation Action'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report summary
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
                  Row(
                    children: [
                      Icon(widget.report.reportType.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.report.reportType.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.report.contentType.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.report.reason,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.report.additionalDetails != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.report.additionalDetails!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action selection
            Text(
              'Select Action:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            ..._actions.entries.map((entry) {
              final action = entry.key;
              final info = entry.value;
              
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(info.icon, size: 20, color: info.color),
                    const SizedBox(width: 8),
                    Text(info.title),
                  ],
                ),
                subtitle: Text(info.description),
                value: action,
                groupValue: _selectedAction,
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            
            const SizedBox(height: 16),
            
            // Notes field
            Text(
              'Moderation Notes:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: _selectedAction == 'warn' 
                    ? 'Enter warning message for users...'
                    : 'Add notes about this moderation action...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            
            // Warning for destructive actions
            if (_selectedAction == 'delete') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The content will be permanently deleted.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || _selectedAction == null
              ? null
              : _takeAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAction == 'delete' 
                ? Colors.red 
                : Theme.of(context).primaryColor,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Take Action'),
        ),
      ],
    );
  }

  Future<void> _takeAction() async {
    if (_selectedAction == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take moderation action on content
      if (_selectedAction != 'no_action') {
        await ModerationService.moderateContent(
          contentId: widget.report.reportedContentId,
          contentType: widget.report.contentType,
          action: _selectedAction!,
          reason: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
      }

      // Update report status
      await ModerationService.updateReportStatus(
        reportId: widget.report.id,
        status: ReportStatus.resolved,
        moderationAction: _actions[_selectedAction]!.title,
        moderationNotes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      widget.onActionTaken?.call();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Action taken: ${_actions[_selectedAction]!.title}'),
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
                Text('Failed to take action: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class ModerationActionInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  ModerationActionInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}