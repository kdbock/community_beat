// lib/screens/polls/poll_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import '../../models/poll.dart';
import '../../services/poll_service.dart';
import '../../widgets/polls/poll_card.dart';

class PollDetailScreen extends StatefulWidget {
  final Poll poll;

  const PollDetailScreen({
    super.key,
    required this.poll,
  });

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  Poll? _currentPoll;
  Map<String, dynamic>? _pollResults;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPoll = widget.poll;
    _loadPollDetails();
  }

  Future<void> _loadPollDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get updated poll data
      final poll = await PollService.getPoll(widget.poll.id);
      if (poll != null) {
        _currentPoll = poll;
      }

      // Get detailed results
      final results = await PollService.getPollResults(widget.poll.id);

      if (mounted) {
        setState(() {
          _pollResults = results;
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
        title: const Text('Poll Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _sharePoll,
            icon: const Icon(Icons.share),
            tooltip: 'Share poll',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              if (_currentPoll?.canVote == true)
                const PopupMenuItem(
                  value: 'vote',
                  child: Row(
                    children: [
                      Icon(Icons.how_to_vote, size: 20),
                      SizedBox(width: 8),
                      Text('Vote'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'results',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20),
                    SizedBox(width: 8),
                    Text('View Results'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
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
            'Failed to load poll details',
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
            onPressed: _loadPollDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currentPoll == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Poll card
          PollCard(
            poll: _currentPoll!,
            onVoted: _loadPollDetails,
          ),
          
          // Detailed information
          _buildDetailedInfo(),
          
          // Results section
          if (_pollResults != null) _buildResultsSection(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poll Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Creator info
            _buildInfoRow(
              Icons.person,
              'Created by',
              _currentPoll!.creatorName,
            ),
            
            // Creation date
            _buildInfoRow(
              Icons.access_time,
              'Created',
              timeago.format(_currentPoll!.createdAt),
            ),
            
            // Expiration
            if (_currentPoll!.expiresAt != null)
              _buildInfoRow(
                Icons.schedule,
                _currentPoll!.isExpired ? 'Expired' : 'Expires',
                timeago.format(_currentPoll!.expiresAt!),
                color: _currentPoll!.isExpired ? Colors.red : Colors.orange,
              ),
            
            // Category
            _buildInfoRow(
              _currentPoll!.category.icon,
              'Category',
              _currentPoll!.category.displayName,
              color: _currentPoll!.category.color,
            ),
            
            // Tags
            if (_currentPoll!.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tag,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tags:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _currentPoll!.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey[100],
                          labelStyle: const TextStyle(fontSize: 12),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
            
            // Settings
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildSettingChip(
                  _currentPoll!.allowMultipleVotes ? 'Multiple Votes' : 'Single Vote',
                  _currentPoll!.allowMultipleVotes ? Colors.blue : Colors.grey,
                ),
                _buildSettingChip(
                  _currentPoll!.isAnonymous ? 'Anonymous' : 'Public Voting',
                  _currentPoll!.isAnonymous ? Colors.purple : Colors.grey,
                ),
                _buildSettingChip(
                  _currentPoll!.isActive ? 'Active' : 'Inactive',
                  _currentPoll!.isActive ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildResultsSection() {
    final results = _pollResults!;
    final poll = results['poll'] as Poll;
    final votes = results['votes'] as List<PollVote>;
    final totalVotes = results['total_votes'] as int;
    final uniqueVoters = results['unique_voters'] as int;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalVotes votes from $uniqueVoters voters',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Winning options
            if (poll.winningOptions.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber[600]),
                        const SizedBox(width: 8),
                        Text(
                          poll.winningOptions.length == 1 ? 'Winner' : 'Tied Winners',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...poll.winningOptions.map((option) {
                      final percentage = option.getPercentage(totalVotes);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${option.text} - ${option.voteCount} votes (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Participation stats
            if (totalVotes > 0) ...[
              Text(
                'Participation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Votes',
                      totalVotes.toString(),
                      Icons.how_to_vote,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Unique Voters',
                      uniqueVoters.toString(),
                      Icons.people,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              if (poll.allowMultipleVotes && totalVotes != uniqueVoters) ...[
                const SizedBox(height: 8),
                _buildStatCard(
                  'Avg Votes per Voter',
                  (totalVotes / uniqueVoters).toStringAsFixed(1),
                  Icons.analytics,
                  Colors.purple,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadPollDetails();
        break;
      case 'vote':
        // Scroll to poll card for voting
        break;
      case 'results':
        // Already showing results
        break;
    }
  }

  void _sharePoll() {
    final poll = _currentPoll!;
    final text = '''
Check out this community poll: "${poll.title}"

${poll.description.isNotEmpty ? poll.description : 'Cast your vote and see what the community thinks!'}

Category: ${poll.category.displayName}
${poll.totalVotes} votes so far

#CommunityBeat #Poll #${poll.category.displayName}
''';

    Share.share(text, subject: 'Community Poll: ${poll.title}');
  }
}