// lib/screens/business/business_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_review.dart';
import '../../models/business.dart';
import '../../services/business_review_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/index.dart';
import 'write_review_screen.dart';

class BusinessReviewsScreen extends StatefulWidget {
  final Business business;

  const BusinessReviewsScreen({
    super.key,
    required this.business,
  });

  @override
  State<BusinessReviewsScreen> createState() => _BusinessReviewsScreenState();
}

class _BusinessReviewsScreenState extends State<BusinessReviewsScreen> {
  List<BusinessReview> _reviews = [];
  ReviewSummary? _summary;
  bool _isLoading = true;
  ReviewSortBy _sortBy = ReviewSortBy.newest;
  int? _filterRating;
  bool _verifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviews = await BusinessReviewService.getBusinessReviews(
        widget.business.id,
        sortBy: _sortBy,
      );
      final summary = await BusinessReviewService.getReviewSummary(widget.business.id);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reviews: $e')),
        );
      }
    }
  }

  Future<void> _navigateToWriteReview() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to write a review')),
      );
      return;
    }

    // Check if user already has a review
    final existingReview = await BusinessReviewService.getUserReviewForBusiness(
      authProvider.currentUser!.uid,
      widget.business.id,
    );

    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WriteReviewScreen(
            business: widget.business,
            existingReview: existingReview,
          ),
        ),
      );

      if (result == true) {
        _loadReviews(); // Refresh reviews
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ReviewSortBy.values.map((sortBy) {
              return ListTile(
                title: Text(_getSortByText(sortBy)),
                leading: Radio<ReviewSortBy>(
                  value: sortBy,
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    Navigator.pop(context);
                    _loadReviews();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rating'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterRating == null,
                  onSelected: (selected) {
                    setState(() {
                      _filterRating = null;
                    });
                    Navigator.pop(context);
                    _loadReviews();
                  },
                ),
                for (int i = 5; i >= 1; i--)
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$i'),
                        const Icon(Icons.star, size: 16),
                      ],
                    ),
                    selected: _filterRating == i,
                    onSelected: (selected) {
                      setState(() {
                        _filterRating = selected ? i : null;
                      });
                      Navigator.pop(context);
                      _loadReviews();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Verified reviews only'),
              value: _verifiedOnly,
              onChanged: (value) {
                setState(() {
                  _verifiedOnly = value ?? false;
                });
                Navigator.pop(context);
                _loadReviews();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: const Text(
          'Reviews',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToWriteReview,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.rate_review),
        label: const Text('Write Review'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Business Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: widget.business.imageUrl != null
                                ? Image.network(
                                    widget.business.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.business),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.business),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.business.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.business.category,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Review Summary
                  if (_summary != null) _buildReviewSummary(_summary!),

                  const SizedBox(height: 16),

                  // Reviews List
                  if (_reviews.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to review this business!',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._reviews.map((review) => _buildReviewCard(review)),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildReviewSummary(ReviewSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          Icon(
                            Icons.star,
                            size: 20,
                            color: i <= summary.averageRating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                      ],
                    ),
                    Text(
                      '${summary.totalReviews} review${summary.totalReviews == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rating Distribution
            for (int i = 5; i >= 1; i--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$i'),
                    const Icon(Icons.star, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: summary.getRatingPercentage(i),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(summary.getRatingPercentage(i) * 100).round()}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (summary.topTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Popular mentions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: summary.topTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BusinessReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info and Rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.userPhotoUrl != null
                      ? NetworkImage(review.userPhotoUrl!)
                      : null,
                  child: review.userPhotoUrl == null
                      ? Text(review.userName.isNotEmpty ? review.userName[0] : 'U')
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
                Row(
                  children: [
                    for (int i = 1; i <= 5; i++)
                      Icon(
                        Icons.star,
                        size: 16,
                        color: i <= review.rating ? Colors.amber : Colors.grey[300],
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
                          'Response from ${widget.business.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
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
                TextButton.icon(
                  onPressed: () => _toggleHelpful(review),
                  icon: Icon(
                    review.isHelpfulBy(
                      Provider.of<AuthProvider>(context, listen: false).currentUser?.uid ?? '',
                    )
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    size: 16,
                  ),
                  label: Text('Helpful (${review.helpfulCount})'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _reportReview(review),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Report'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleHelpful(BusinessReview review) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to mark reviews as helpful')),
      );
      return;
    }

    try {
      final isCurrentlyHelpful = review.isHelpfulBy(authProvider.currentUser!.uid);
      await BusinessReviewService.markReviewHelpful(
        review.id,
        authProvider.currentUser!.uid,
        !isCurrentlyHelpful,
      );
      _loadReviews(); // Refresh to show updated count
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _reportReview(BusinessReview review) async {
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
            ...['Inappropriate content', 'Spam', 'Fake review', 'Other'].map(
              (reason) => ListTile(
                title: Text(reason),
                onTap: () => Navigator.pop(context, reason),
              ),
            ),
          ],
        ),
      ),
    );

    if (reason != null) {
      try {
        await BusinessReviewService.reportReview(
          review.id,
          authProvider.currentUser!.uid,
          reason,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review reported successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reporting review: $e')),
        );
      }
    }
  }

  String _getSortByText(ReviewSortBy sortBy) {
    switch (sortBy) {
      case ReviewSortBy.newest:
        return 'Newest First';
      case ReviewSortBy.oldest:
        return 'Oldest First';
      case ReviewSortBy.highestRated:
        return 'Highest Rated';
      case ReviewSortBy.lowestRated:
        return 'Lowest Rated';
      case ReviewSortBy.mostHelpful:
        return 'Most Helpful';
    }
  }
}