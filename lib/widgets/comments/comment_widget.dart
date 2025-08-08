// lib/widgets/comments/comment_widget.dart

import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../services/comment_service.dart';
import '../global/custom_snackbar.dart';

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;
  final bool showReplies;
  final int depth;

  const CommentWidget({
    super.key,
    required this.comment,
    this.onReply,
    this.onUpdate,
    this.onDelete,
    this.showReplies = true,
    this.depth = 0,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;
  bool _showEditForm = false;
  final _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _initializeState() {
    _likeCount = widget.comment.likeCount;
    // TODO: Check if current user has liked this comment
    _editController.text = widget.comment.content;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: widget.depth * 16.0,
        bottom: 8,
      ),
      child: Card(
        elevation: widget.depth > 0 ? 1 : 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCommentHeader(),
              const SizedBox(height: 8),
              _showEditForm ? _buildEditForm() : _buildCommentContent(),
              const SizedBox(height: 8),
              _buildCommentActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            widget.comment.displayUserName.isNotEmpty
                ? widget.comment.displayUserName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.comment.displayUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatDate(widget.comment.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (widget.comment.isEdited)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'edited',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reply',
              child: Row(
                children: [
                  Icon(Icons.reply),
                  SizedBox(width: 8),
                  Text('Reply'),
                ],
              ),
            ),
            // TODO: Only show edit/delete for comment owner
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
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Report'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentContent() {
    return Text(
      widget.comment.displayContent,
      style: TextStyle(
        fontSize: 14,
        color: widget.comment.isDeleted || widget.comment.isModerated
            ? Colors.grey
            : null,
        fontStyle: widget.comment.isDeleted || widget.comment.isModerated
            ? FontStyle.italic
            : null,
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        TextFormField(
          controller: _editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _showEditForm = false;
                  _editController.text = widget.comment.content;
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEdit,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentActions() {
    return Row(
      children: [
        InkWell(
          onTap: _isLoading ? null : _toggleLike,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: _isLiked ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _likeCount.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: widget.onReply,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reply, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Reply',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (widget.comment.isReply)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'reply',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reply':
        widget.onReply?.call();
        break;
      case 'edit':
        setState(() => _showEditForm = true);
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  Future<void> _toggleLike() async {
    setState(() => _isLoading = true);
    try {
      await CommentService.toggleCommentLike(widget.comment.id);
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to update like');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveEdit() async {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty) {
      CustomSnackBar.showError(context, 'Comment cannot be empty');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await CommentService.updateComment(
        commentId: widget.comment.id,
        content: newContent,
      );
      
      setState(() => _showEditForm = false);
      widget.onUpdate?.call();
      
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Comment updated');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to update comment');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment() async {
    setState(() => _isLoading = true);
    try {
      await CommentService.deleteComment(widget.comment.id);
      widget.onDelete?.call();
      
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Comment deleted');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to delete comment');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: const Text('Thank you for helping keep our community safe. This comment will be reviewed by our moderation team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reportComment();
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportComment() async {
    try {
      await CommentService.reportComment(
        commentId: widget.comment.id,
        reason: 'Inappropriate content',
      );
      
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Comment reported');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to report comment');
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}