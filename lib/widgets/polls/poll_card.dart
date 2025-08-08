// lib/widgets/polls/poll_card.dart

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/poll.dart';
import '../../services/poll_service.dart';

class PollCard extends StatefulWidget {
  final Poll poll;
  final VoidCallback? onTap;
  final VoidCallback? onVoted;
  final bool showResults;
  final bool isCompact;

  const PollCard({
    super.key,
    required this.poll,
    this.onTap,
    this.onVoted,
    this.showResults = false,
    this.isCompact = false,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  PollVote? _userVote;
  bool _isVoting = false;
  Set<String> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    try {
      final vote = await PollService.getUserVote(widget.poll.id);
      if (mounted) {
        setState(() {
          _userVote = vote;
          if (vote != null) {
            _selectedOptions = vote.selectedOptionIds.toSet();
          }
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _vote() async {
    if (_selectedOptions.isEmpty || _isVoting) return;

    setState(() {
      _isVoting = true;
    });

    try {
      await PollService.voteOnPoll(
        pollId: widget.poll.id,
        selectedOptionIds: _selectedOptions.toList(),
      );

      await _loadUserVote();
      widget.onVoted?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Vote submitted successfully!'),
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
                Text('Failed to vote: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVoted = _userVote != null;
    final showResults = widget.showResults || hasVoted || !widget.poll.canVote;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 12),
              
              // Title and description
              _buildContent(),
              
              const SizedBox(height: 16),
              
              // Poll options
              if (!widget.isCompact) ...[
                _buildOptions(showResults),
                const SizedBox(height: 16),
              ],
              
              // Footer with stats and actions
              _buildFooter(showResults, hasVoted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.poll.category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.poll.category.icon,
                size: 14,
                color: widget.poll.category.color,
              ),
              const SizedBox(width: 4),
              Text(
                widget.poll.category.displayName,
                style: TextStyle(
                  color: widget.poll.category.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Status indicators
        if (!widget.poll.canVote) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.poll.isExpired ? Colors.red[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.poll.isExpired ? 'EXPIRED' : 'CLOSED',
              style: TextStyle(
                fontSize: 10,
                color: widget.poll.isExpired ? Colors.red[700] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        
        if (_userVote != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'VOTED',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.poll.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.poll.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.poll.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: widget.isCompact ? 2 : null,
            overflow: widget.isCompact ? TextOverflow.ellipsis : null,
          ),
        ],
      ],
    );
  }

  Widget _buildOptions(bool showResults) {
    return Column(
      children: widget.poll.options.map((option) {
        final isSelected = _selectedOptions.contains(option.id);
        final percentage = option.getPercentage(widget.poll.totalVotes);
        final isWinning = showResults && widget.poll.winningOptions.contains(option);

        if (showResults) {
          return _buildResultOption(option, percentage, isWinning);
        } else {
          return _buildVotingOption(option, isSelected);
        }
      }).toList(),
    );
  }

  Widget _buildVotingOption(PollOption option, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: widget.poll.canVote ? () {
          setState(() {
            if (widget.poll.allowMultipleVotes) {
              if (isSelected) {
                _selectedOptions.remove(option.id);
              } else {
                _selectedOptions.add(option.id);
              }
            } else {
              _selectedOptions.clear();
              _selectedOptions.add(option.id);
            }
          });
        } : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.poll.allowMultipleVotes
                    ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                    : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              if (option.icon != null) ...[
                Icon(option.icon, size: 20, color: option.color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.text,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (option.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultOption(PollOption option, double percentage, bool isWinning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isWinning ? Colors.green : Colors.grey[300]!,
            width: isWinning ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isWinning ? Colors.green.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: 20, color: option.color),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                fontWeight: isWinning ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${option.voteCount} votes (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (option.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          option.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isWinning) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber[600],
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isWinning ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool showResults, bool hasVoted) {
    return Row(
      children: [
        // Creator and time info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.poll.creatorName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(widget.poll.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (widget.poll.expiresAt != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: widget.poll.isExpired ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.poll.isExpired 
                          ? 'Expired ${timeago.format(widget.poll.expiresAt!)}'
                          : 'Expires ${timeago.format(widget.poll.expiresAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.poll.isExpired ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Vote count
        if (showResults) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.how_to_vote,
                  size: 14,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.poll.totalVotes} votes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Vote button
        if (!showResults && widget.poll.canVote && !widget.isCompact) ...[
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _selectedOptions.isNotEmpty && !_isVoting ? _vote : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: _isVoting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Vote'),
          ),
        ],
      ],
    );
  }
}