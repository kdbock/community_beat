// lib/widgets/business/review_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_review.dart';
import '../../models/business.dart';
import '../../services/business_review_service.dart';
import '../../providers/auth_provider.dart';

class ReviewCard extends StatelessWidget {
  final BusinessReview review;
  final Business? business;
  final VoidCallback? onUpdate;
  final bool showBusinessInfo;

  const ReviewCard({
    super.key,
    required this.review,
    this.business,
    this.onUpdate,
    this.showBusinessInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Info (if showing)
            if (showBusinessInfo && business != null) ...[
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: business!.imageUrl != null
                        ? Image.network(
                            business!.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                              child: const Icon(Icons.business, size: 20),
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Icon(Icons.business, size: 20),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          business!.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],

            // User Info and Rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.userPhotoUrl != null
                      ? NetworkImage(review.userPhotoUrl!)
                      : null,
                  child: review.userPhotoUrl == null
                      ? Text(
                          review.userName.isNotEmpty ? review.userName[0] : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (review.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                          ],
                        ],
                      ),
                      Text(
                        review.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 1; i <= 5; i++)
                          Icon(
                            Icons.star,
                            size: 16,
                            color: i <= review.rating ? Colors.amber : Colors.grey[300],
                          ),
                      ],
                    ),
                    Text(
                      review.ratingText,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Review Title
            Text(
              review.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Review Comment
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),

            // Tags
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: review.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Images
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.imageUrls[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Business Response
            if (review.hasBusinessResponse) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Response from business',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (review.businessResponseDate != null)
                          Text(
                            _formatResponseDate(review.businessResponseDate!),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.businessResponse!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                _HelpfulButton(
                  review: review,
                  onUpdate: onUpdate,
                ),
                const SizedBox(width: 16),
                _ReportButton(
                  review: review,
                  onUpdate: onUpdate,
                ),
                const Spacer(),
                if (review.status != ReviewStatus.active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      review.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
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

  String _formatResponseDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _HelpfulButton extends StatefulWidget {
  final BusinessReview review;
  final VoidCallback? onUpdate;

  const _HelpfulButton({
    required this.review,
    this.onUpdate,
  });

  @override
  State<_HelpfulButton> createState() => _HelpfulButtonState();
}

class _HelpfulButtonState extends State<_HelpfulButton> {
  bool _isLoading = false;

  Future<void> _toggleHelpful() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to mark reviews as helpful')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isCurrentlyHelpful = widget.review.isHelpfulBy(authProvider.currentUser!.uid);
      await BusinessReviewService.markReviewHelpful(
        widget.review.id,
        authProvider.currentUser!.uid,
        !isCurrentlyHelpful,
      );
      
      widget.onUpdate?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isHelpful = authProvider.currentUser != null && 
        widget.review.isHelpfulBy(authProvider.currentUser!.uid);

    return TextButton.icon(
      onPressed: _isLoading ? null : _toggleHelpful,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
            ),
      label: Text('Helpful (${widget.review.helpfulCount})'),
      style: TextButton.styleFrom(
        foregroundColor: isHelpful 
            ? Theme.of(context).primaryColor 
            : Colors.grey[600],
      ),
    );
  }
}

class _ReportButton extends StatefulWidget {
  final BusinessReview review;
  final VoidCallback? onUpdate;

  const _ReportButton({
    required this.review,
    this.onUpdate,
  });

  @override
  State<_ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<_ReportButton> {
  bool _isLoading = false;

  Future<void> _reportReview() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report reviews')),
      );
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this review?'),
            const SizedBox(height: 16),
            ...['Inappropriate content', 'Spam', 'Fake review', 'Harassment', 'Other'].map(
              (reason) => ListTile(
                title: Text(reason),
                onTap: () => Navigator.pop(context, reason),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (reason != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await BusinessReviewService.reportReview(
          widget.review.id,
          authProvider.currentUser!.uid,
          reason,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review reported successfully')),
          );
          widget.onUpdate?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reporting review: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isReported = authProvider.currentUser != null && 
        widget.review.isReportedBy(authProvider.currentUser!.uid);

    return TextButton.icon(
      onPressed: _isLoading || isReported ? null : _reportReview,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isReported ? Icons.flag : Icons.flag_outlined,
              size: 16,
            ),
      label: Text(isReported ? 'Reported' : 'Report'),
      style: TextButton.styleFrom(
        foregroundColor: isReported 
            ? Colors.red 
            : Colors.grey[600],
      ),
    );
  }
}