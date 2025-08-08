// lib/widgets/business/review_summary.dart

import 'package:flutter/material.dart';
import '../../models/business_review.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final ReviewSummary summary;
  final VoidCallback? onViewAllReviews;
  final bool showViewAllButton;

  const ReviewSummaryWidget({
    super.key,
    required this.summary,
    this.onViewAllReviews,
    this.showViewAllButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.totalReviews == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.star_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No reviews yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to review!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rating and view all button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.ratingText,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showViewAllButton && onViewAllReviews != null)
                  TextButton(
                    onPressed: onViewAllReviews,
                    child: const Text('View All'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Rating overview
            Row(
              children: [
                // Large rating number
                Text(
                  summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Stars and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Star rating
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
                      const SizedBox(height: 4),
                      
                      // Review count and verified count
                      Text(
                        '${summary.totalReviews} review${summary.totalReviews == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (summary.verifiedReviews > 0)
                        Text(
                          '${summary.verifiedReviews} verified',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Rating distribution bars
            const Text(
              'Rating Distribution',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            for (int i = 5; i >= 1; i--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // Star number
                    Text(
                      '$i',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 8),
                    
                    // Progress bar
                    Expanded(
                      child: LinearProgressIndicator(
                        value: summary.getRatingPercentage(i),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getRatingColor(i),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Count and percentage
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${summary.ratingDistribution[i] ?? 0}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '(${(summary.getRatingPercentage(i) * 100).round()}%)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),

            // Popular tags
            if (summary.topTags.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Popular Mentions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: summary.topTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
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
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class CompactReviewSummary extends StatelessWidget {
  final ReviewSummary summary;
  final VoidCallback? onTap;

  const CompactReviewSummary({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.totalReviews == 0) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'No reviews',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              summary.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '(${summary.totalReviews})',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final bool allowHalfRating;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.color,
    this.unratedColor,
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Colors.amber;
    final inactiveColor = unratedColor ?? Colors.grey[300]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starRating = index + 1;
        
        if (allowHalfRating) {
          if (rating >= starRating) {
            // Full star
            return Icon(
              Icons.star,
              size: size,
              color: activeColor,
            );
          } else if (rating >= starRating - 0.5) {
            // Half star
            return Icon(
              Icons.star_half,
              size: size,
              color: activeColor,
            );
          } else {
            // Empty star
            return Icon(
              Icons.star_outline,
              size: size,
              color: inactiveColor,
            );
          }
        } else {
          return Icon(
            rating >= starRating ? Icons.star : Icons.star_outline,
            size: size,
            color: rating >= starRating ? activeColor : inactiveColor,
          );
        }
      }),
    );
  }
}