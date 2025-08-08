// lib/screens/event_feedback_screen.dart

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_feedback.dart';
import '../services/event_feedback_service.dart';
import '../widgets/index.dart';

class EventFeedbackScreen extends StatefulWidget {
  final Event event;

  const EventFeedbackScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventFeedbackScreen> createState() => _EventFeedbackScreenState();
}

class _EventFeedbackScreenState extends State<EventFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _commentController = TextEditingController();
  
  int _rating = 5;
  List<String> _selectedTags = [];
  bool _isAnonymous = false;
  bool _isLoading = false;
  
  EventFeedback? _userFeedback;
  List<EventFeedback> _allFeedback = [];
  EventRating? _eventRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeedbackData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbackData() async {
    setState(() => _isLoading = true);
    try {
      final userFeedback = await EventFeedbackService.getUserFeedback(widget.event.id);
      final allFeedback = await EventFeedbackService.getEventFeedback(widget.event.id);
      final eventRating = await EventFeedbackService.getEventRating(widget.event.id);
      
      if (mounted) {
        setState(() {
          _userFeedback = userFeedback;
          _allFeedback = allFeedback;
          _eventRating = eventRating;
          
          // Pre-fill form if user has existing feedback
          if (userFeedback != null) {
            _rating = userFeedback.rating;
            _commentController.text = userFeedback.comment ?? '';
            _selectedTags = List.from(userFeedback.tags);
            _isAnonymous = userFeedback.isAnonymous;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to load feedback data');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Feedback',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.event.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Leave Feedback', icon: Icon(Icons.rate_review)),
            Tab(text: 'All Reviews', icon: Icon(Icons.reviews)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeedbackForm(),
                _buildFeedbackList(),
              ],
            ),
    );
  }

  Widget _buildFeedbackForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventSummary(),
          const SizedBox(height: 24),
          _buildRatingSection(),
          const SizedBox(height: 24),
          _buildTagsSection(),
          const SizedBox(height: 24),
          _buildCommentSection(),
          const SizedBox(height: 24),
          _buildAnonymousToggle(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildEventSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organized by ${widget.event.organizer}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _formatEventDate(widget.event.startDate),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Rating',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  starIndex <= _rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: starIndex <= _rating ? Colors.amber : Colors.grey,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _getRatingText(_rating),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What best describes this event?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackTags.all.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            final primary = Theme.of(context).primaryColor;
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: primary.withValues(
                red: ((primary.r * 255.0).round() & 0xff).toDouble(),
                green: ((primary.g * 255.0).round() & 0xff).toDouble(),
                blue: ((primary.b * 255.0).round() & 0xff).toDouble(),
                alpha: 0.2 * 255,
              ),
              checkmarkColor: primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Comments (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _commentController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Share your thoughts about the event...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnonymousToggle() {
    return Row(
      children: [
        Checkbox(
          value: _isAnonymous,
          onChanged: (value) => setState(() => _isAnonymous = value ?? false),
        ),
        const Expanded(
          child: Text(
            'Submit feedback anonymously',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _userFeedback != null ? 'Update Feedback' : 'Submit Feedback',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildFeedbackList() {
    if (_allFeedback.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Reviews Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to leave a review for this event!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_eventRating != null) _buildRatingSummary(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allFeedback.length,
            itemBuilder: (context, index) {
              final feedback = _allFeedback[index];
              return _buildFeedbackCard(feedback);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummary() {
    final rating = _eventRating!;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Text(
                rating.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rating.totalRatings} review${rating.totalRatings != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rating.commonTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: rating.commonTags
                  .map((tag) {
                        final primary = Theme.of(context).primaryColor;
                        return Chip(
                          label: Text(tag),
                          backgroundColor: primary.withValues(
                            red: ((primary.r * 255.0).round() & 0xff).toDouble(),
                            green: ((primary.g * 255.0).round() & 0xff).toDouble(),
                            blue: ((primary.b * 255.0).round() & 0xff).toDouble(),
                            alpha: 0.1 * 255,
                          ),
                        );
                      })
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(EventFeedback feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  feedback.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(feedback.createdAt),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(feedback.comment!),
            ],
            if (feedback.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: feedback.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    setState(() => _isLoading = true);
    final messengerContext = context;
    try {
      if (_userFeedback != null) {
        // Update existing feedback
        await EventFeedbackService.updateFeedback(
          feedbackId: _userFeedback!.id,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          tags: _selectedTags,
          isAnonymous: _isAnonymous,
        );
        if (mounted) CustomSnackBar.showSuccess(messengerContext, 'Feedback updated successfully!');
      } else {
        // Submit new feedback
        await EventFeedbackService.submitFeedback(
          eventId: widget.event.id,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          tags: _selectedTags,
          isAnonymous: _isAnonymous,
        );
        if (mounted) CustomSnackBar.showSuccess(messengerContext, 'Feedback submitted successfully!');
      }
      
      await _loadFeedbackData(); // Refresh data
      if (mounted) _tabController.animateTo(1); // Switch to reviews tab
    } catch (e) {
      if (mounted) CustomSnackBar.showError(messengerContext, 'Failed to submit feedback');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  String _formatEventDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}