// lib/widgets/reactions/reaction_button.dart

import 'package:flutter/material.dart';
import '../../models/reaction.dart';
import '../../models/comment.dart';
import '../../services/reaction_service.dart';
import '../global/custom_snackbar.dart';

class ReactionButton extends StatefulWidget {
  final String contentId;
  final ContentType contentType;
  final bool showCount;
  final bool showText;
  final double iconSize;
  final VoidCallback? onReactionChanged;

  const ReactionButton({
    super.key,
    required this.contentId,
    required this.contentType,
    this.showCount = true,
    this.showText = false,
    this.iconSize = 20,
    this.onReactionChanged,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  ReactionSummary? _reactionSummary;
  bool _isLoading = false;
  bool _showReactionPicker = false;

  @override
  void initState() {
    super.initState();
    _loadReactionSummary();
  }

  Future<void> _loadReactionSummary() async {
    try {
      final summary = await ReactionService.getReactionSummary(
        contentId: widget.contentId,
        contentType: widget.contentType,
      );
      
      if (mounted) {
        setState(() => _reactionSummary = summary);
      }
    } catch (e) {
      // Silently fail - reactions are not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReactionButton(),
        if (_showReactionPicker) _buildReactionPicker(),
        if (widget.showCount && _reactionSummary != null && _reactionSummary!.totalReactions > 0)
          _buildReactionSummary(),
      ],
    );
  }

  Widget _buildReactionButton() {
    final hasReacted = _reactionSummary?.hasUserReacted ?? false;
    final userReaction = _reactionSummary?.userReaction;
    final totalReactions = _reactionSummary?.totalReactions ?? 0;

    return InkWell(
      onTap: _isLoading ? null : _handleQuickReaction,
      onLongPress: _isLoading ? null : _showReactionPickerDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted 
                  ? (userReaction?.color.withValues(
                      red: ((userReaction.color.r * 255.0).round() & 0xff).toDouble(),
                      green: ((userReaction.color.g * 255.0).round() & 0xff).toDouble(),
                      blue: ((userReaction.color.b * 255.0).round() & 0xff).toDouble(),
                      alpha: 0.1 * 255,
                    ) ?? Colors.grey[100])
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: hasReacted 
              ? Border.all(color: userReaction?.color ?? Colors.grey, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasReacted && userReaction != null) ...[
              Text(
                userReaction.emoji,
                style: TextStyle(fontSize: widget.iconSize),
              ),
            ] else ...[
              Icon(
                Icons.thumb_up_outlined,
                size: widget.iconSize,
                color: Colors.grey[600],
              ),
            ],
            if (widget.showCount && totalReactions > 0) ...[
              const SizedBox(width: 4),
              Text(
                totalReactions.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: hasReacted 
                      ? (userReaction?.color ?? Colors.grey[600])
                      : Colors.grey[600],
                  fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
            if (widget.showText) ...[
              const SizedBox(width: 4),
              Text(
                hasReacted 
                    ? (userReaction?.displayName ?? 'Like')
                    : 'Like',
                style: TextStyle(
                  fontSize: 12,
                  color: hasReacted 
                      ? (userReaction?.color ?? Colors.grey[600])
                      : Colors.grey[600],
                  fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPicker() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
                color: Colors.black.withValues(
                  red: ((Colors.black.r * 255.0).round() & 0xff).toDouble(),
                  green: ((Colors.black.g * 255.0).round() & 0xff).toDouble(),
                  blue: ((Colors.black.b * 255.0).round() & 0xff).toDouble(),
                  alpha: 0.1 * 255,
                ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReactionType.values.map((type) {
          final isSelected = _reactionSummary?.userReaction == type;
          return GestureDetector(
            onTap: () => _handleReactionSelect(type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? type.color.withValues(
                  red: ((type.color.r * 255.0).round() & 0xff).toDouble(),
                  green: ((type.color.g * 255.0).round() & 0xff).toDouble(),
                  blue: ((type.color.b * 255.0).round() & 0xff).toDouble(),
                  alpha: 0.2 * 255,
                ) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReactionSummary() {
    final summary = _reactionSummary!;
    final topReactions = summary.topReactions;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: _showReactionDetails,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show top reaction emojis
            if (topReactions.isNotEmpty) ...[
              ...topReactions.take(3).map((type) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              )),
              const SizedBox(width: 4),
            ],
            Text(
              summary.generateSummaryText(),
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

  Future<void> _handleQuickReaction() async {
    setState(() => _isLoading = true);
    try {
      await ReactionService.toggleReaction(
        contentId: widget.contentId,
        contentType: widget.contentType,
        reactionType: ReactionType.like,
      );
      
      await _loadReactionSummary();
      widget.onReactionChanged?.call();
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to update reaction');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleReactionSelect(ReactionType type) async {
    setState(() {
      _showReactionPicker = false;
      _isLoading = true;
    });
    
    try {
      await ReactionService.toggleReaction(
        contentId: widget.contentId,
        contentType: widget.contentType,
        reactionType: type,
      );
      
      await _loadReactionSummary();
      widget.onReactionChanged?.call();
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to update reaction');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReactionPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Reaction'),
        content: Wrap(
          spacing: 16,
          children: ReactionType.values.map((type) {
            final isSelected = _reactionSummary?.userReaction == type;
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _handleReactionSelect(type);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? type.color.withValues(
                    red: ((type.color.r * 255.0).round() & 0xff).toDouble(),
                    green: ((type.color.g * 255.0).round() & 0xff).toDouble(),
                    blue: ((type.color.b * 255.0).round() & 0xff).toDouble(),
                    alpha: 0.2 * 255,
                  ) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected 
                      ? Border.all(color: type.color, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? type.color : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReactionDetails() {
    if (_reactionSummary == null || _reactionSummary!.totalReactions == 0) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reactions (${_reactionSummary!.totalReactions})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ReactionType.values.where((type) {
              return _reactionSummary!.getCount(type) > 0;
            }).map((type) {
              final count = _reactionSummary!.getCount(type);
              return ListTile(
                leading: Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(type.displayName),
                trailing: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}