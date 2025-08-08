// lib/screens/moderation/moderation_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/moderation_service.dart';
import '../../widgets/moderation/report_card.dart';
import '../../widgets/moderation/moderation_stats_card.dart';

class ModerationDashboardScreen extends StatefulWidget {
  const ModerationDashboardScreen({super.key});

  @override
  State<ModerationDashboardScreen> createState() => _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends State<ModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportStatus? _selectedStatus;
  ReportedContentType? _selectedContentType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showModerationStats,
            tooltip: 'View Statistics',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Reports',
            onSelected: _handleFilterSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Filter by Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...ReportStatus.values.map((status) => PopupMenuItem(
                value: 'status_${status.toString().split('.').last}',
                child: Row(
                  children: [
                    Icon(status.icon, color: status.color),
                    const SizedBox(width: 8),
                    Text(status.displayName),
                  ],
                ),
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Filter by Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...ReportedContentType.values.map((type) => PopupMenuItem(
                value: 'content_${type.toString().split('.').last}',
                child: Row(
                  children: [
                    Icon(type.icon),
                    const SizedBox(width: 8),
                    Text(type.displayName),
                  ],
                ),
              )),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.schedule)),
            Tab(text: 'Under Review', icon: Icon(Icons.visibility)),
            Tab(text: 'Resolved', icon: Icon(Icons.check_circle)),
            Tab(text: 'All Reports', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(ReportStatus.pending),
          _buildReportsTab(ReportStatus.underReview),
          _buildReportsTab(ReportStatus.resolved),
          _buildReportsTab(null), // All reports
        ],
      ),
    );
  }

  Widget _buildReportsTab(ReportStatus? status) {
    return StreamBuilder<List<Report>>(
      stream: ModerationService.getReports(
        status: _selectedStatus ?? status,
        contentType: _selectedContentType,
        limit: 100,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading reports',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == null ? Icons.inbox : status.icon,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  status == null
                      ? 'No reports found'
                      : 'No ${status.displayName.toLowerCase()} reports',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  status == ReportStatus.pending
                      ? 'Great! No pending reports to review.'
                      : 'Reports will appear here when available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReportCard(
                  report: report,
                  onStatusChanged: () => setState(() {}),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleFilterSelection(String value) {
    setState(() {
      if (value == 'clear_filters') {
        _selectedStatus = null;
        _selectedContentType = null;
      } else if (value.startsWith('status_')) {
        final statusName = value.substring(7);
        _selectedStatus = ReportStatus.values.firstWhere(
          (s) => s.toString().split('.').last == statusName,
        );
      } else if (value.startsWith('content_')) {
        final contentName = value.substring(8);
        _selectedContentType = ReportedContentType.values.firstWhere(
          (c) => c.toString().split('.').last == contentName,
        );
      }
    });
  }

  void _showModerationStats() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Moderation Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const Expanded(
                child: ModerationStatsCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}