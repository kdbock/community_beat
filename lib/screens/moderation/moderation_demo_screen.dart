// lib/screens/moderation/moderation_demo_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/bulletin/post_card.dart';
import '../../widgets/moderation/report_button.dart';
import '../../models/report.dart';
import '../../services/moderation_service.dart';
import 'moderation_dashboard_screen.dart';

class ModerationDemoScreen extends StatefulWidget {
  const ModerationDemoScreen({super.key});

  @override
  State<ModerationDemoScreen> createState() => _ModerationDemoScreenState();
}

class _ModerationDemoScreenState extends State<ModerationDemoScreen> {
  bool _canModerate = false;

  @override
  void initState() {
    super.initState();
    _checkModerationPermissions();
  }

  Future<void> _checkModerationPermissions() async {
    final canModerate = await ModerationService.canModerate();
    if (mounted) {
      setState(() {
        _canModerate = canModerate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_canModerate)
            IconButton(
              icon: const Icon(Icons.shield),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModerationDashboardScreen(),
                  ),
                );
              },
              tooltip: 'Moderation Dashboard',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Content Moderation System',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This demo showcases the comprehensive content moderation system. Users can report inappropriate content, and moderators can review and take action on reports.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Features list
                    _buildFeaturesList(),
                    
                    const SizedBox(height: 16),
                    
                    // Moderation status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _canModerate ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _canModerate ? Colors.green[200]! : Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _canModerate ? Icons.admin_panel_settings : Icons.person,
                            color: _canModerate ? Colors.green[700] : Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _canModerate
                                  ? 'You have moderation privileges. You can access the moderation dashboard.'
                                  : 'You are viewing as a regular user. You can report content but cannot moderate.',
                              style: TextStyle(
                                color: _canModerate ? Colors.green[700] : Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Demo content section
            Text(
              'Sample Content (Try Reporting)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Sample posts that can be reported
            ..._buildSamplePosts(),
            
            const SizedBox(height: 24),
            
            // Report button examples
            Text(
              'Report Button Examples',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Different Report Button Styles:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    
                    // Icon only button
                    Row(
                      children: [
                        const Text('Icon Only: '),
                        ReportButton(
                          contentId: 'demo-content-1',
                          contentType: ReportedContentType.post,
                          reportedUserId: 'demo-user-1',
                          reportedUserName: 'Demo User',
                          contentSnapshot: const {
                            'title': 'Demo Content',
                            'content': 'This is demo content for testing',
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Text button
                    Row(
                      children: [
                        const Text('With Text: '),
                        ReportButton(
                          contentId: 'demo-content-2',
                          contentType: ReportedContentType.comment,
                          reportedUserId: 'demo-user-2',
                          reportedUserName: 'Another User',
                          isIconOnly: false,
                          contentSnapshot: const {
                            'content': 'This is a demo comment',
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Comprehensive reporting system with multiple report types',
      'Content snapshots for context preservation',
      'Moderation dashboard for admins and moderators',
      'Real-time report status tracking',
      'Moderation actions: hide, delete, warn, or dismiss',
      'Detailed moderation statistics and analytics',
      'User-friendly report dialog with guided options',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  List<Widget> _buildSamplePosts() {
    final samplePosts = [
      {
        'id': 'demo-post-1',
        'title': 'Looking for a reliable plumber',
        'description': 'Hi everyone! I need a trustworthy plumber for some kitchen repairs. Any recommendations?',
        'category': 'Services',
        'authorName': 'Sarah Johnson',
        'authorId': 'user-sarah-123',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': 'demo-post-2',
        'title': 'Community Garden Volunteer Day',
        'description': 'Join us this Saturday for our monthly community garden cleanup! Bring gloves and water.',
        'category': 'Events',
        'authorName': 'Mike Chen',
        'authorId': 'user-mike-456',
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': 'demo-post-3',
        'title': 'Selling vintage bicycle',
        'description': 'Beautiful 1980s road bike in excellent condition. Perfect for weekend rides around the neighborhood.',
        'category': 'Sell',
        'authorName': 'Emma Davis',
        'authorId': 'user-emma-789',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    return samplePosts.map((post) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PostCard(
        id: post['id'] as String,
        title: post['title'] as String,
        description: post['description'] as String,
        category: post['category'] as String,
        authorName: post['authorName'] as String,
        authorId: post['authorId'] as String,
        createdAt: post['createdAt'] as DateTime,
        isOwner: false, // Demo posts are not owned by current user
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This is a demo post. Try using the report option!'),
            ),
          );
        },
      ),
    )).toList();
  }
}