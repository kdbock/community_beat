// lib/screens/event_rsvp_list_screen.dart

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/rsvp.dart';
import '../services/rsvp_service.dart';
import '../widgets/index.dart';

class EventRSVPListScreen extends StatefulWidget {
  final Event event;

  const EventRSVPListScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventRSVPListScreen> createState() => _EventRSVPListScreenState();
}

class _EventRSVPListScreenState extends State<EventRSVPListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RSVP> _allRSVPs = [];
  Map<RSVPStatus, int> _rsvpCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: RSVPStatus.values.length, vsync: this);
    _loadRSVPs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRSVPs() async {
    setState(() => _isLoading = true);
    try {
      final rsvps = await RSVPService.getEventRSVPs(widget.event.id);
      final counts = await RSVPService.getEventRSVPCounts(widget.event.id);
      
      if (mounted) {
        setState(() {
          _allRSVPs = rsvps;
          _rsvpCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.showError(context, 'Failed to load RSVPs');
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
              'Event Attendees',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRSVPs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: RSVPStatus.values
              .map((status) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(status.emoji),
                        const SizedBox(width: 4),
                        Text(status.displayName),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_rsvpCounts[status] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: RSVPStatus.values
                  .map((status) => _buildRSVPList(status))
                  .toList(),
            ),
    );
  }

  Widget _buildRSVPList(RSVPStatus status) {
    final rsvpsForStatus = _allRSVPs
        .where((rsvp) => rsvp.status == status)
        .toList();

    if (rsvpsForStatus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.displayName.toLowerCase()} responses',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When people RSVP as "${status.displayName}", they\'ll appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRSVPs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rsvpsForStatus.length,
        itemBuilder: (context, index) {
          final rsvp = rsvpsForStatus[index];
          return _buildRSVPCard(rsvp);
        },
      ),
    );
  }

  Widget _buildRSVPCard(RSVP rsvp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRSVPStatusColor(rsvp.status),
          child: Text(
            rsvp.status.emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        title: Text(
          rsvp.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rsvp.userEmail.isNotEmpty)
              Text(
                rsvp.userEmail,
                style: const TextStyle(color: Colors.grey),
              ),
            Text(
              'RSVP\'d ${_formatDate(rsvp.rsvpDate)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            if (rsvp.partySize != null && rsvp.partySize! > 1)
              Text(
                'Party size: ${rsvp.partySize}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            if (rsvp.notes != null && rsvp.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Note: ${rsvp.notes}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getRSVPStatusColor(rsvp.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            rsvp.status.displayName,
            style: TextStyle(
              color: _getRSVPStatusColor(rsvp.status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
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