// lib/screens/polls/polls_screen.dart

import 'package:flutter/material.dart';
import '../../models/poll.dart';
import '../../services/poll_service.dart';
import '../../widgets/polls/poll_card.dart';
import 'create_poll_screen.dart';
import 'poll_detail_screen.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  PollCategory? _selectedCategory;
  List<Poll> _polls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPolls();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final polls = await PollService.getActivePolls(
        category: _selectedCategory,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _polls = polls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Polls'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.how_to_vote)),
            Tab(text: 'My Polls', icon: Icon(Icons.person)),
            Tab(text: 'Results', icon: Icon(Icons.bar_chart)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by category',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter indicator
          if (_selectedCategory != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _selectedCategory!.color.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    _selectedCategory!.icon,
                    size: 16,
                    color: _selectedCategory!.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtered by: ${_selectedCategory!.displayName}',
                    style: TextStyle(
                      color: _selectedCategory!.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                      _loadPolls();
                    },
                    child: Text(
                      'Clear Filter',
                      style: TextStyle(color: _selectedCategory!.color),
                    ),
                  ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildMyPollsTab(),
                _buildResultsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPoll,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              'Failed to load polls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPolls,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.poll_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Polls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != null
                  ? 'No polls found in ${_selectedCategory!.displayName} category'
                  : 'Be the first to create a community poll!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createPoll,
              icon: const Icon(Icons.add),
              label: const Text('Create Poll'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPolls,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _polls.length,
        itemBuilder: (context, index) {
          final poll = _polls[index];
          return PollCard(
            poll: poll,
            onTap: () => _openPollDetail(poll),
            onVoted: _loadPolls,
          );
        },
      ),
    );
  }

  Widget _buildMyPollsTab() {
    return FutureBuilder<List<Poll>>(
      future: PollService.getUserPolls(),
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
                  'Failed to load your polls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final userPolls = snapshot.data ?? [];

        if (userPolls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.poll_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Polls Created',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You haven\'t created any polls yet.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createPoll,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First Poll'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: userPolls.length,
          itemBuilder: (context, index) {
            final poll = userPolls[index];
            return PollCard(
              poll: poll,
              showResults: true,
              onTap: () => _openPollDetail(poll),
            );
          },
        );
      },
    );
  }

  Widget _buildResultsTab() {
    final completedPolls = _polls.where((poll) => 
        !poll.canVote || poll.totalVotes > 0).toList();

    if (completedPolls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Poll results will appear here once voting begins.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: completedPolls.length,
      itemBuilder: (context, index) {
        final poll = completedPolls[index];
        return PollCard(
          poll: poll,
          showResults: true,
          onTap: () => _openPollDetail(poll),
        );
      },
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // All categories option
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All Categories'),
                selected: _selectedCategory == null,
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                  Navigator.pop(context);
                  _loadPolls();
                },
              ),
              
              const Divider(),
              
              // Category options
              ...PollCategory.values.map((category) {
                return ListTile(
                  leading: Icon(category.icon, color: category.color),
                  title: Text(category.displayName),
                  selected: _selectedCategory == category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                    _loadPolls();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createPoll() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePollScreen(),
      ),
    );

    if (result == true) {
      _loadPolls();
    }
  }

  void _openPollDetail(Poll poll) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PollDetailScreen(poll: poll),
      ),
    ).then((_) => _loadPolls());
  }
}