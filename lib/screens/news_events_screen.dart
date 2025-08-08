// lib/screens/news_events_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../widgets/index.dart' hide NewsEventsProvider;
import '../providers/news_events_provider.dart';

class NewsEventsScreen extends StatefulWidget {
  const NewsEventsScreen({super.key});

  @override
  State<NewsEventsScreen> createState() => _NewsEventsScreenState();
}

class _NewsEventsScreenState extends State<NewsEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsEventsProvider>().loadNews();
      context.read<NewsEventsProvider>().loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsEventsProvider>(
      builder: (context, provider, child) {
        return ScaffoldWrapper(
          appBar: AppBar(
            title: const Text(
              'News & Events',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  InAppNotification.show(
                    context,
                    title: 'Notifications',
                    message: 'You have 3 new notifications',
                    icon: Icons.notifications,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  provider.loadNews();
                  provider.loadEvents();
                  CustomSnackBar.showInfo(
                    context,
                    'Refreshing news and events...',
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Feed', icon: Icon(Icons.feed)),
                Tab(text: 'Calendar', icon: Icon(Icons.calendar_today)),
                Tab(text: 'Alerts', icon: Icon(Icons.warning)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFeedTab(provider),
              _buildCalendarTab(provider),
              _buildAlertsTab(provider),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              CustomSnackBar.showInfo(
                context,
                'Add new event feature coming soon!',
              );
            },
            tooltip: 'Add new event',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildFeedTab(NewsEventsProvider provider) {
    final newsItems =
        _getMockEvents()
            .map(
              (event) => NewsItem(
                id: event.id,
                title: event.title,
                description: event.description,
                imageUrl: event.imageUrl,
                publishedAt: event.startDate,
                isEvent: event.category != 'Alert',
                eventDate: event.startDate,
                onTap: () {
                  CustomSnackBar.showInfo(context, 'Opening ${event.title}...');
                },
              ),
            )
            .toList();

    return NewsList(
      newsItems: newsItems,
      isLoading: provider.isLoading,
      onRefresh: () {
        provider.loadNews();
        provider.loadEvents();
      },
    );
  }

  Widget _buildCalendarTab(NewsEventsProvider provider) {
    final eventDates =
        _getMockEvents()
            .where((event) => event.category != 'Alert')
            .map((event) => event.startDate)
            .toList();

    return Column(
      children: [
        EventCalendar(
          eventDates: eventDates,
          selectedDay: provider.selectedDate,
          onDaySelected: (date) {
            provider.setSelectedDate(date);
            CustomSnackBar.showInfo(
              context,
              'Selected ${date.day}/${date.month}/${date.year}',
            );
          },
        ),
        Expanded(
          child:
              provider.selectedDate != null
                  ? _buildEventsForDate(provider.selectedDate!)
                  : const Center(
                    child: Text(
                      'Select a date to view events',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab(NewsEventsProvider provider) {
    final alerts =
        _getMockEvents()
            .where((event) => event.category == 'Alert' || event.isUrgent)
            .toList();

    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Active Alerts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All clear! No emergency alerts at this time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return CustomListView<Event>(
      items: alerts,
      itemBuilder:
          (context, alert, index) => NewsCard(
            title: alert.title,
            description: alert.description,
            imageUrl: alert.imageUrl,
            publishedAt: alert.startDate,
            isEvent: false,
            onTap: () {
              CustomAlertDialog.showInfo(
                context,
                title: alert.title,
                message: alert.description,
              );
            },
          ),
      isLoading: provider.isLoading,
      onRefresh: () => provider.loadNews(),
    );
  }

  Widget _buildEventsForDate(DateTime date) {
    final eventsForDate =
        _getMockEvents()
            .where(
              (event) =>
                  event.startDate.year == date.year &&
                  event.startDate.month == date.month &&
                  event.startDate.day == date.day,
            )
            .toList();

    if (eventsForDate.isEmpty) {
      return const Center(
        child: Text(
          'No events on this date',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return CustomListView<Event>(
      items: eventsForDate,
      itemBuilder:
          (context, event, index) => NewsCard(
            title: event.title,
            description: event.description,
            imageUrl: event.imageUrl,
            publishedAt: event.startDate,
            isEvent: true,
            eventDate: event.startDate,
            onTap: () {
              CustomSnackBar.showInfo(context, 'Opening ${event.title}...');
            },
          ),
    );
  }

  List<Event> _getMockEvents() {
    return [
      Event(
        id: '1',
        title: 'Town Hall Meeting',
        description:
            'Monthly town hall meeting to discuss community issues and upcoming projects.',
        startDate: DateTime.now().add(const Duration(days: 3)),
        location: 'City Hall, Main Street',
        category: 'Government',
        organizer: 'City Council',
        contactInfo: 'townhall@city.gov',
      ),
      Event(
        id: '2',
        title: 'Summer Festival',
        description:
            'Annual summer festival with live music, food vendors, and family activities.',
        startDate: DateTime.now().add(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 17)),
        location: 'Central Park',
        category: 'Entertainment',
        organizer: 'Parks & Recreation',
        contactInfo: 'events@city.gov',
      ),
      Event(
        id: '3',
        title: 'Road Closure Alert',
        description:
            'Main Street will be closed for construction from 8 AM to 5 PM.',
        startDate: DateTime.now().add(const Duration(days: 1)),
        location: 'Main Street (between 1st and 3rd Ave)',
        category: 'Alert',
        organizer: 'Public Works',
        isUrgent: true,
      ),
    ];
  }
}
