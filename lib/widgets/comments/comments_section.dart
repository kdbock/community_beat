// lib/widgets/comments/comments_section.dart

import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../services/comment_service.dart';
import '../global/custom_snackbar.dart';
import 'comment_widget.dart';

class CommentsSection extends StatefulWidget {
  final String contentId;
  final ContentType contentType;
  final bool showAddComment;
  final int maxCommentsToShow;
  final bool expandable;

  const CommentsSection({
    super.key,
    required this.contentId,
    required this.contentType,
    this.showAddComment = true,
    this.maxCommentsToShow = 10,
    this.expandable = true,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _commentController = TextEditingController();
  final _replyController = TextEditingController();
  
  List<CommentThread> _commentThreads = [];
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _showReplyForm = false;
  String? _replyToCommentId;
  int _totalComments = 0;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final threads = await CommentService.getCommentThreads(
        contentId: widget.contentId,
        contentType: widget.contentType,
        limit: _isExpanded ? 100 : widget.maxCommentsToShow,
      );
      
      final count = await CommentService.getCommentCount(
        contentId: widget.contentId,
        contentType: widget.contentType,
      );
      
      if (mounted) {
        setState(() {
          _commentThreads = threads;
          _totalComments = count;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to load comments');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentsHeader(),
        if (widget.showAddComment) ...[
          const SizedBox(height: 16),
          _buildAddCommentForm(),
        ],
        if (_showReplyForm) ...[
          const SizedBox(height: 16),
          _buildReplyForm(),
        ],
        const SizedBox(height: 16),
        _buildCommentsList(),
        if (widget.expandable && _totalComments > widget.maxCommentsToShow && !_isExpanded)
          _buildExpandButton(),
      ],
    );
  }

  Widget _buildCommentsHeader() {
    return Row(
      children: [
        const Icon(Icons.comment, size: 20),
        const SizedBox(width: 8),
        Text(
          'Comments ($_totalComments)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_totalComments > 0)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComments,
            tooltip: 'Refresh comments',
          ),
      ],
    );
  }

  Widget _buildAddCommentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a comment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _commentController.clear();
                  },
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post Comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyForm() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.reply, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Reply to comment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showReplyForm = false;
                      _replyToCommentId = null;
                      _replyController.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _replyController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Write your reply...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showReplyForm = false;
                      _replyToCommentId = null;
                      _replyController.clear();
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoading && _commentThreads.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_commentThreads.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No comments yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share your thoughts!',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _commentThreads.map((thread) => _buildCommentThread(thread)).toList(),
    );
  }

  Widget _buildCommentThread(CommentThread thread) {
    return Column(
      children: [
        CommentWidget(
          comment: thread.comment,
          onReply: () => _showReplyToComment(thread.comment.id),
          onUpdate: _loadComments,
          onDelete: _loadComments,
          depth: 0,
        ),
        // Show replies
        ...thread.replies.map((reply) => _buildReplyWidget(reply, 1)),
      ],
    );
  }

  Widget _buildReplyWidget(CommentThread reply, int depth) {
    return Column(
      children: [
        CommentWidget(
          comment: reply.comment,
          onReply: () => _showReplyToComment(reply.comment.parentCommentId!),
          onUpdate: _loadComments,
          onDelete: _loadComments,
          depth: depth,
        ),
        // Nested replies (limit depth to avoid infinite nesting)
        if (depth < 3)
          ...reply.replies.map((nestedReply) => _buildReplyWidget(nestedReply, depth + 1)),
      ],
    );
  }

  Widget _buildExpandButton() {
    final remainingComments = _totalComments - widget.maxCommentsToShow;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() => _isExpanded = true);
            _loadComments();
          },
          icon: const Icon(Icons.expand_more),
          label: Text('Show $remainingComments more comments'),
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      CustomSnackBar.showError(context, 'Please enter a comment');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await CommentService.addComment(
        contentId: widget.contentId,
        contentType: widget.contentType,
        content: content,
      );
      
      _commentController.clear();
      await _loadComments();
      
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Comment added successfully');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to add comment');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) {
      CustomSnackBar.showError(context, 'Please enter a reply');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await CommentService.addComment(
        contentId: widget.contentId,
        contentType: widget.contentType,
        content: content,
        parentCommentId: _replyToCommentId,
      );
      
      _replyController.clear();
      setState(() {
        _showReplyForm = false;
        _replyToCommentId = null;
      });
      
      await _loadComments();
      
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Reply added successfully');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to add reply');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReplyToComment(String commentId) {
    setState(() {
      _showReplyForm = true;
      _replyToCommentId = commentId;
    });
  }
}