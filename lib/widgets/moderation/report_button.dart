// lib/widgets/moderation/report_button.dart

import 'package:flutter/material.dart';
import '../../models/report.dart';
import 'report_dialog.dart';

class ReportButton extends StatelessWidget {
  final String contentId;
  final ReportedContentType contentType;
  final String? reportedUserId;
  final String? reportedUserName;
  final Map<String, dynamic>? contentSnapshot;
  final bool isIconOnly;
  final Color? color;

  const ReportButton({
    super.key,
    required this.contentId,
    required this.contentType,
    this.reportedUserId,
    this.reportedUserName,
    this.contentSnapshot,
    this.isIconOnly = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconOnly) {
      return IconButton(
        icon: Icon(
          Icons.flag_outlined,
          size: 18,
          color: color ?? Colors.grey[600],
        ),
        onPressed: () => _showReportDialog(context),
        tooltip: 'Report ${contentType.displayName.toLowerCase()}',
        visualDensity: VisualDensity.compact,
      );
    }

    return TextButton.icon(
      onPressed: () => _showReportDialog(context),
      icon: Icon(
        Icons.flag_outlined,
        size: 16,
        color: color ?? Colors.grey[600],
      ),
      label: Text(
        'Report',
        style: TextStyle(
          color: color ?? Colors.grey[600],
          fontSize: 12,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showReportDialog(
      context: context,
      contentId: contentId,
      contentType: contentType,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      contentSnapshot: contentSnapshot,
    );
  }
}

/// A more subtle report option for overflow menus
class ReportMenuItem extends StatelessWidget {
  final String contentId;
  final ReportedContentType contentType;
  final String? reportedUserId;
  final String? reportedUserName;
  final Map<String, dynamic>? contentSnapshot;

  const ReportMenuItem({
    super.key,
    required this.contentId,
    required this.contentType,
    this.reportedUserId,
    this.reportedUserName,
    this.contentSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuItem<String>(
      value: 'report',
      child: Row(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 18,
            color: Colors.red[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Report ${contentType.displayName}',
            style: TextStyle(
              color: Colors.red[600],
            ),
          ),
        ],
      ),
    );
  }

  void showReportDialog(BuildContext context) {
    showDialog(
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
}