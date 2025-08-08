// lib/screens/business/business_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business.dart';
import '../../models/post.dart';
import '../../models/event.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/index.dart';
import '../forms/business_form_screen.dart';
import '../forms/post_form_screen.dart';
import '../forms/event_form_screen.dart';
import 'business_analytics_screen.dart';
import 'business_reviews_screen.dart';
import 'business_promotions_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Business? _userBusiness;
  List<Post> _businessPosts = [];
  List<Event> _businessEvents = [];
  bool _isLoading = true;
  
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBusinessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.uid;
      
      if (userId != null) {
        // Load user's business
        final firestoreService = FirestoreService();
        final businesses = await firestoreService.getBusinessesByOwner(userId);
        if (businesses.isNotEmpty) {
          _userBusiness = businesses.first;
          
          // Load business posts and events
          final posts = await firestoreService.getPostsByUser(userId);
          final events = await firestoreService.getEventsByOrganizer(userId);
          
          // Load basic analytics
          _analytics = await _loadAnalytics();
          
          if (mounted) {
            setState(() {
              _businessPosts = posts.where((p) => p.type == PostType.business).toList();
              _businessEvents = events;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to load business data');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    if (_userBusiness == null) return {};
    
    try {
      // Basic analytics - in a real app, this would be more sophisticated
      return {
        'total_posts': _businessPosts.length,
        'total_events': _businessEvents.length,
        'total_views': 0, // TODO: Implement view tracking
        'total_reactions': 0, // TODO: Get from reaction service
        'total_comments': 0, // TODO: Get from comment service
        'this_month_posts': _businessPosts.where((p) => 
          p.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))
        ).length,
        'this_month_events': _businessEvents.where((e) => 
          e.startDate.isAfter(DateTime.now().subtract(const Duration(days: 30)))
        ).length,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: const Text(
          'Business Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBusinessData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit_business',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Business'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Analytics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Posts', icon: Icon(Icons.post_add)),
            Tab(text: 'Events', icon: Icon(Icons.event)),
            Tab(text: 'Reviews', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userBusiness == null
              ? _buildNoBusinessView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildPostsTab(),
                    _buildEventsTab(),
                    _buildReviewsTab(),
                  ],
                ),
      floatingActionButton: _userBusiness != null ? _buildFAB() : null,
    );
  }

  Widget _buildNoBusinessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Business Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your business profile to start managing your presence in the community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createBusiness,
              icon: const Icon(Icons.add_business),
              label: const Text('Create Business Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBusinessCard(),
          const SizedBox(height: 24),
          _buildAnalyticsCards(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildBusinessCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: _userBusiness!.imageUrl != null
                      ? NetworkImage(_userBusiness!.imageUrl!)
                      : null,
                  child: _userBusiness!.imageUrl == null
                      ? Text(
                          _userBusiness!.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userBusiness!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userBusiness!.category,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      if (_userBusiness!.isVerified)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editBusiness(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _userBusiness!.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _userBusiness!.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildAnalyticsCard(
              'Total Posts',
              _analytics['total_posts']?.toString() ?? '0',
              Icons.post_add,
              Colors.blue,
            ),
            _buildAnalyticsCard(
              'Total Events',
              _analytics['total_events']?.toString() ?? '0',
              Icons.event,
              Colors.green,
            ),
            _buildAnalyticsCard(
              'This Month Posts',
              _analytics['this_month_posts']?.toString() ?? '0',
              Icons.trending_up,
              Colors.orange,
            ),
            _buildAnalyticsCard(
              'This Month Events',
              _analytics['this_month_events']?.toString() ?? '0',
              Icons.calendar_today,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Create Post',
                Icons.post_add,
                Colors.blue,
                () => _createPost(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Create Event',
                Icons.event,
                Colors.green,
                () => _createEvent(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Analytics',
                Icons.analytics,
                Colors.orange,
                () => _viewAnalytics(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Manage Reviews',
                Icons.star,
                Colors.purple,
                () => _manageReviews(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentPosts = _businessPosts.take(3).toList();
    final recentEvents = _businessEvents.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (recentPosts.isEmpty && recentEvents.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ...recentPosts.map((post) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.post_add, color: Colors.blue),
              title: Text(post.title),
              subtitle: Text('Posted ${_formatDate(post.createdAt)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to post detail
              },
            ),
          )),
          ...recentEvents.map((event) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.green),
              title: Text(event.title),
              subtitle: Text('Created ${_formatDate(event.startDate)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to event detail
              },
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildPostsTab() {
    return _businessPosts.isEmpty
        ? _buildEmptyState(
            'No Posts Yet',
            'Create your first business post to engage with the community.',
            Icons.post_add,
            'Create Post',
            _createPost,
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _businessPosts.length,
            itemBuilder: (context, index) {
              final post = _businessPosts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.post_add, color: Colors.white),
                  ),
                  title: Text(post.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.description),
                      const SizedBox(height: 4),
                      Text(
                        'Posted ${_formatDate(post.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handlePostAction(value, post),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  Widget _buildEventsTab() {
    return _businessEvents.isEmpty
        ? _buildEmptyState(
            'No Events Yet',
            'Create your first business event to bring the community together.',
            Icons.event,
            'Create Event',
            _createEvent,
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _businessEvents.length,
            itemBuilder: (context, index) {
              final event = _businessEvents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.event, color: Colors.white),
                  ),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.description),
                      const SizedBox(height: 4),
                      Text(
                        'Starts ${_formatDate(event.startDate)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleEventAction(value, event),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  Widget _buildReviewsTab() {
    return BusinessReviewsScreen(business: _userBusiness!);
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  FloatingActionButton _buildFAB() {
    return FloatingActionButton(
      onPressed: _showCreateMenu,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create New',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.post_add, color: Colors.blue),
              title: const Text('Business Post'),
              subtitle: const Text('Share updates, promotions, or news'),
              onTap: () {
                Navigator.pop(context);
                _createPost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Colors.green),
              title: const Text('Business Event'),
              subtitle: const Text('Host an event for the community'),
              onTap: () {
                Navigator.pop(context);
                _createEvent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.orange),
              title: const Text('Promotion'),
              subtitle: const Text('Create a special offer or deal'),
              onTap: () {
                Navigator.pop(context);
                _createPromotion();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit_business':
        _editBusiness();
        break;
      case 'analytics':
        _viewAnalytics();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _handlePostAction(String action, Post post) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostFormScreen(existingPost: post),
          ),
        ).then((_) => _loadBusinessData());
        break;
      case 'delete':
        _deletePost(post);
        break;
    }
  }

  void _handleEventAction(String action, Event event) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventFormScreen(existingEvent: event),
          ),
        ).then((_) => _loadBusinessData());
        break;
      case 'delete':
        _deleteEvent(event);
        break;
    }
  }

  void _createBusiness() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BusinessFormScreen(),
      ),
    ).then((_) => _loadBusinessData());
  }

  void _editBusiness() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessFormScreen(existingBusiness: _userBusiness),
      ),
    ).then((_) => _loadBusinessData());
  }

  void _createPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostFormScreen(),
      ),
    ).then((_) => _loadBusinessData());
  }

  void _createEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventFormScreen(),
      ),
    ).then((_) => _loadBusinessData());
  }

  void _createPromotion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessPromotionsScreen(businessId: _userBusiness!.id),
      ),
    ).then((_) => _loadBusinessData());
  }

  void _viewAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessAnalyticsScreen(business: _userBusiness!),
      ),
    );
  }

  void _manageReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessReviewsScreen(business: _userBusiness!),
      ),
    );
  }

  void _showSettings() {
    // TODO: Implement business settings
    CustomSnackBar.showInfo(context, 'Business settings coming soon!');
  }

  void _deletePost(Post post) async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete "${post.title}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
    
    if (confirmed == true) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.deletePost(post.id);
        _loadBusinessData();
        if (mounted) {
          CustomSnackBar.showSuccess(context, 'Post deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, 'Failed to delete post');
        }
      }
    }
  }

  void _deleteEvent(Event event) async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context,
      title: 'Delete Event',
      message: 'Are you sure you want to delete "${event.title}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
    
    if (confirmed == true) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.deleteEvent(event.id);
        _loadBusinessData();
        if (mounted) {
          CustomSnackBar.showSuccess(context, 'Event deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, 'Failed to delete event');
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}