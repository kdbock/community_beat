// lib/screens/firestore_test_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/post.dart';
import '../models/business.dart';
import '../models/event.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Integration Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DataProvider>().refreshAllData();
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (!dataProvider.isInitialized && dataProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Firestore...'),
                ],
              ),
            );
          }

          if (dataProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${dataProvider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      dataProvider.clearError();
                      dataProvider.initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Stats
                _buildStatsSection(dataProvider),
                const SizedBox(height: 24),

                // Posts Section
                _buildPostsSection(dataProvider),
                const SizedBox(height: 24),

                // Businesses Section
                _buildBusinessesSection(dataProvider),
                const SizedBox(height: 24),

                // Events Section
                _buildEventsSection(dataProvider),
                const SizedBox(height: 24),

                // Test Actions
                _buildTestActions(dataProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(DataProvider dataProvider) {
    final stats = dataProvider.dashboardStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Posts', stats['total_posts'] ?? 0),
                _buildStatItem('Businesses', stats['total_businesses'] ?? 0),
                _buildStatItem('Events', stats['upcoming_events'] ?? 0),
                _buildStatItem('Requests', stats['pending_service_requests'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPostsSection(DataProvider dataProvider) {
    final posts = dataProvider.posts;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Posts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${posts.length} posts'),
              ],
            ),
            const SizedBox(height: 12),
            if (posts.isEmpty)
              const Text('No posts found')
            else
              ...posts.take(3).map((post) => _buildPostItem(post)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getPostTypeColor(post.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${post.category} • ${post.timeAgo}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.general:
        return Colors.brown;
      case PostType.buySell:
        return Colors.green;
      case PostType.job:
        return Colors.blue;
      case PostType.housing:
        return Colors.orange;
      case PostType.lostFound:
        return Colors.red;
      case PostType.volunteer:
        return Colors.purple;
      case PostType.service:
        return Colors.teal;
      case PostType.event:
        return Colors.indigo;
      case PostType.other:
        return Colors.grey;
    }
  }

  Widget _buildBusinessesSection(DataProvider dataProvider) {
    final businesses = dataProvider.businesses;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Businesses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${businesses.length} businesses'),
              ],
            ),
            const SizedBox(height: 12),
            if (businesses.isEmpty)
              const Text('No businesses found')
            else
              ...businesses.take(3).map((business) => _buildBusinessItem(business)),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessItem(Business business) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            business.isVerified ? Icons.verified : Icons.business,
            size: 16,
            color: business.isVerified ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${business.category} • ${business.rating.toStringAsFixed(1)} ⭐',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(DataProvider dataProvider) {
    final events = dataProvider.events;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${events.length} events'),
              ],
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const Text('No events found')
            else
              ...events.take(3).map((event) => _buildEventItem(event)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            event.isUrgent ? Icons.priority_high : Icons.event,
            size: 16,
            color: event.isUrgent ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${event.category} • ${_formatDate(event.startDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';
    
    return '${date.month}/${date.day}';
  }

  Widget _buildTestActions(DataProvider dataProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _createTestPost(dataProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Test Post'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _createTestBusiness(dataProvider),
                  icon: const Icon(Icons.business),
                  label: const Text('Add Test Business'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _createTestEvent(dataProvider),
                  icon: const Icon(Icons.event),
                  label: const Text('Add Test Event'),
                ),
                ElevatedButton.icon(
                  onPressed: () => dataProvider.refreshAllData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createTestPost(DataProvider dataProvider) {
    final post = Post(
      id: '',
      title: 'Test Post ${DateTime.now().millisecondsSinceEpoch}',
      description: 'This is a test post created from the Firestore test screen.',
      type: PostType.other,
      category: 'Test',
      authorName: 'Test User',
      createdAt: DateTime.now(),
    );

    dataProvider.createPost(post);
  }

  void _createTestBusiness(DataProvider dataProvider) {
    final business = Business(
      id: '',
      name: 'Test Business ${DateTime.now().millisecondsSinceEpoch}',
      description: 'This is a test business created from the Firestore test screen.',
      category: 'Test',
      address: '123 Test Street',
      phone: '(555) 123-4567',
      rating: 4.0,
    );

    dataProvider.createBusiness(business);
  }

  void _createTestEvent(DataProvider dataProvider) {
    final event = Event(
      id: '',
      title: 'Test Event ${DateTime.now().millisecondsSinceEpoch}',
      description: 'This is a test event created from the Firestore test screen.',
      startDate: DateTime.now().add(const Duration(days: 7)),
      location: 'Test Location',
      category: 'Test',
      organizer: 'Test Organizer',
    );

    dataProvider.createEvent(event);
  }
}