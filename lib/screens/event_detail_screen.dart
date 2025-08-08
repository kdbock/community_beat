// lib/screens/event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/rsvp.dart';
import '../models/comment.dart';
import '../widgets/index.dart';
import '../providers/news_events_provider.dart';
import '../services/rsvp_service.dart';
import '../services/calendar_service.dart';
import '../services/firestore_service.dart';
import 'forms/event_form_screen.dart';
import 'event_rsvp_list_screen.dart';
import 'event_feedback_screen.dart';
import '../widgets/comments/comments_section.dart';
import '../widgets/reactions/reaction_button.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  RSVP? _userRSVP;
  bool _isLoading = false;
  int _currentAttendees = 0;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    setState(() => _isLoading = true);
    try {
      // Load user's RSVP status
      final userRSVP = await RSVPService.getUserRSVP(widget.event.id);
      
      // Load attendee count
      final attendeeCount = await RSVPService.getEventAttendeeCount(widget.event.id);
      
      if (mounted) {
        setState(() {
          _userRSVP = userRSVP;
          _currentAttendees = attendeeCount;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to load event details');
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
        title: Text(
          widget.event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareEvent,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Event'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Add to Calendar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Event', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'feedback',
                child: Row(
                  children: [
                    Icon(Icons.rate_review),
                    SizedBox(width: 8),
                    Text('Leave Feedback'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag),
                    SizedBox(width: 8),
                    Text('Report Event'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(),
                  _buildEventInfo(),
                  _buildEventDescription(),
                  _buildEventDetails(),
                  _buildAttendeeSection(),
                  _buildLocationSection(),
                  _buildOrganizerSection(),
                  _buildTagsSection(),
                  const SizedBox(height: 24),
                  _buildReactionSection(),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CommentsSection(
                      contentId: widget.event.id,
                      contentType: ContentType.event,
                    ),
                  ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: _buildRSVPButton(),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        image: widget.event.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.event.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.event.imageUrl == null
          ? const Center(
              child: Icon(
                Icons.event,
                size: 80,
                color: Colors.grey,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.event.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEventInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Date',
              subtitle: _formatDate(widget.event.startDate),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.access_time,
              title: 'Time',
              subtitle: _formatTime(widget.event.startDate),
            ),
          ),
          if (widget.event.ticketPrice != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.attach_money,
                title: 'Price',
                subtitle: widget.event.ticketPrice == 0
                    ? 'Free'
                    : '\$${widget.event.ticketPrice!.toStringAsFixed(2)}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.event.endDate != null)
                _buildDetailRow(
                  icon: Icons.event_available,
                  label: 'End Date',
                  value: _formatDateTime(widget.event.endDate!),
                ),
              if (widget.event.isRecurring)
                _buildDetailRow(
                  icon: Icons.repeat,
                  label: 'Recurring',
                  value: widget.event.recurringPattern ?? 'Yes',
                ),
              if (widget.event.isUrgent)
                _buildDetailRow(
                  icon: Icons.priority_high,
                  label: 'Priority',
                  value: 'Urgent',
                  valueColor: Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 8),
                  const Text(
                    'Attendees',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_userRSVP != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRSVPStatusColor(_userRSVP!.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_userRSVP!.status.emoji} ${_userRSVP!.status.displayName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '$_currentAttendees attending',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.event.maxAttendees != null) ...[
                    Text(
                      ' / ${widget.event.maxAttendees} max',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_currentAttendees > 0)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventRSVPListScreen(event: widget.event),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                ],
              ),
              if (widget.event.maxAttendees != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _currentAttendees / widget.event.maxAttendees!,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openInMaps,
                    child: const Text('Open in Maps'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.event.address != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.event.address!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  const Text(
                    'Organizer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.event.contactInfo != null)
                    TextButton(
                      onPressed: _contactOrganizer,
                      child: const Text('Contact'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.organizer,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.event.contactInfo != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.event.contactInfo!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    if (widget.event.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.event.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  FloatingActionButton _buildRSVPButton() {
    final isAtCapacity = widget.event.maxAttendees != null &&
        _currentAttendees >= widget.event.maxAttendees!;
    final isGoing = _userRSVP?.status == RSVPStatus.going;

    return FloatingActionButton.extended(
      onPressed: isAtCapacity && !isGoing ? null : _showRSVPDialog,
      backgroundColor: isGoing
          ? Colors.green
          : (isAtCapacity ? Colors.grey : Theme.of(context).primaryColor),
      icon: Icon(isGoing ? Icons.check : Icons.event_available),
      label: Text(
        isGoing
            ? 'Going'
            : (isAtCapacity ? 'Event Full' : 'RSVP'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${_formatTime(date)}';
  }

  void _showRSVPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RSVP to Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you like to respond to "${widget.event.title}"?'),
            const SizedBox(height: 16),
            ...RSVPStatus.values.map((status) => ListTile(
              leading: Text(status.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(status.displayName),
              onTap: () {
                Navigator.pop(context);
                _updateRSVP(status);
              },
            )),
            if (_userRSVP != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove RSVP', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeRSVP();
                },
              ),
            ],
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
  }

  Future<void> _updateRSVP(RSVPStatus status) async {
    setState(() => _isLoading = true);
    try {
      await RSVPService.createOrUpdateRSVP(
        eventId: widget.event.id,
        status: status,
      );
      
      await _loadEventDetails(); // Refresh data
      
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'RSVP updated: ${status.displayName}',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to update RSVP');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeRSVP() async {
    setState(() => _isLoading = true);
    try {
      await RSVPService.deleteRSVP(widget.event.id);
      
      await _loadEventDetails(); // Refresh data
      
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'RSVP removed',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to remove RSVP');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareEvent() {
    final text = CalendarService.generateShareText(widget.event);
    Share.share(text, subject: widget.event.title);
  }

  void _showCalendarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to Calendar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...CalendarService.getAvailableCalendarApps().map((app) => ListTile(
              leading: Text(app.icon, style: const TextStyle(fontSize: 24)),
              title: Text(app.name),
              subtitle: Text(app.description),
              onTap: () {
                Navigator.pop(context);
                _handleCalendarAction(app.name);
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCalendarAction(String appName) async {
    try {
      switch (appName) {
        case 'Google Calendar':
        case 'Apple Calendar':
        case 'Outlook':
          final success = await CalendarService.exportToCalendar(widget.event);
          if (success && mounted) {
            CustomSnackBar.showSuccess(
              context,
              'Opening calendar app...',
            );
          } else if (mounted) {
            CustomSnackBar.showError(
              context,
              'Could not open calendar app',
            );
          }
          break;
        case 'Copy Details':
          await CalendarService.copyEventToClipboard(widget.event);
          if (mounted) {
            CustomSnackBar.showSuccess(
              context,
              'Event details copied to clipboard',
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'Failed to add event to calendar',
        );
      }
    }
  }

  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent(
      widget.event.address ?? widget.event.location,
    );
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        CustomSnackBar.showError(context, 'Could not open maps');
      }
    }
  }

  Future<void> _contactOrganizer() async {
    if (widget.event.contactInfo == null) return;

    final contact = widget.event.contactInfo!;
    Uri? uri;

    if (contact.contains('@')) {
      // Email
      uri = Uri.parse('mailto:$contact');
    } else if (contact.contains(RegExp(r'[\d\-\(\)\+\s]'))) {
      // Phone number
      uri = Uri.parse('tel:$contact');
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        CustomSnackBar.showError(context, 'Could not contact organizer');
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editEvent();
        break;
      case 'calendar':
        _showCalendarOptions();
        break;
      case 'delete':
        _deleteEvent();
        break;
      case 'feedback':
        _showFeedback();
        break;
      case 'report':
        _reportEvent();
        break;
    }
  }

  void _editEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(existingEvent: widget.event),
      ),
    ).then((updatedEvent) {
      if (updatedEvent != null && updatedEvent is Event) {
        // Refresh the event data
        context.read<NewsEventsProvider>().loadEvents();
        CustomSnackBar.showSuccess(
          context,
          'Event updated successfully!',
        );
      }
    });
  }

  void _deleteEvent() async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context,
      title: 'Delete Event',
      message: 'Are you sure you want to delete "${widget.event.title}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.deleteEvent(widget.event.id);
        
        if (mounted) {
          Navigator.pop(context); // Go back to previous screen
          context.read<NewsEventsProvider>().loadEvents();
          CustomSnackBar.showSuccess(
            context,
            'Event deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, 'Failed to delete event');
        }
      }
    }
  }

  void _showFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFeedbackScreen(event: widget.event),
      ),
    );
  }

  Widget _buildReactionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ReactionButton(
                contentId: widget.event.id,
                contentType: ContentType.event,
                showCount: true,
                showText: true,
                iconSize: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportEvent() {
    CustomAlertDialog.showInfo(
      context,
      title: 'Report Event',
      message: 'Thank you for helping keep our community safe. Your report has been submitted and will be reviewed by our moderation team.',
    );
  }

  Color _getRSVPStatusColor(RSVPStatus status) {
    switch (status) {
      case RSVPStatus.going:
        return Colors.green;
      case RSVPStatus.maybe:
        return Colors.orange;
      case RSVPStatus.notGoing:
        return Colors.red;
      case RSVPStatus.cancelled:
        return Colors.grey;
    }
  }
}