// lib/screens/search/news_events_search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/news_events_provider.dart';
import '../../models/news_item.dart';
import '../../widgets/news_events/news_card.dart';

class NewsEventsSearchScreen extends StatefulWidget {
  const NewsEventsSearchScreen({super.key});

  @override
  State<NewsEventsSearchScreen> createState() => _NewsEventsSearchScreenState();
}

class _NewsEventsSearchScreenState extends State<NewsEventsSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<NewsItem> _filteredNews = [];
  List<NewsItem> _filteredEvents = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _isSearching = query.isNotEmpty;
      });
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredNews = [];
        _filteredEvents = [];
      });
      return;
    }

    final provider = context.read<NewsEventsProvider>();
    
    setState(() {
      // Filter news (non-event items)
      _filteredNews = provider.news.where((newsItem) {
        return newsItem.title.toLowerCase().contains(query) ||
               newsItem.description.toLowerCase().contains(query);
      }).toList();

      // Filter events (event items)
      _filteredEvents = provider.events.where((eventItem) {
        return eventItem.title.toLowerCase().contains(query) ||
               eventItem.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search news and events...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'News${_isSearching ? ' (${_filteredNews.length})' : ''}',
              icon: const Icon(Icons.article),
            ),
            Tab(
              text: 'Events${_isSearching ? ' (${_filteredEvents.length})' : ''}',
              icon: const Icon(Icons.event),
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    if (!_isSearching) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Search News',
        subtitle: 'Enter keywords to search through news articles',
      );
    }

    if (_filteredNews.isEmpty) {
      return _buildEmptyState(
        icon: Icons.article_outlined,
        title: 'No news found',
        subtitle: 'Try different keywords or check the Events tab',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNews.length,
      itemBuilder: (context, index) {
        final news = _filteredNews[index];
        return NewsCard(
          title: news.title,
          description: news.description,
          imageUrl: news.imageUrl,
          publishedAt: news.publishedAt,
          onTap: () => _showNewsDetails(news),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    if (!_isSearching) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Search Events',
        subtitle: 'Enter keywords to search through community events',
      );
    }

    if (_filteredEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy,
        title: 'No events found',
        subtitle: 'Try different keywords or check the News tab',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(NewsItem event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Event',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(event.eventDate ?? event.publishedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _highlightText(event.title, _searchQuery),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _highlightText(event.description, _searchQuery),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Location not specified',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _highlightText(String text, String query) {
    // For now, just return the original text
    // In a real implementation, you might want to use RichText with highlighting
    return text;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return '$difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showNewsDetails(NewsItem news) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(news.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(news.description),
              const SizedBox(height: 16),
              Text(
                'Published: ${_formatDate(news.publishedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(NewsItem event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.description),
              const SizedBox(height: 16),
              Text(
                'Date: ${_formatDate(event.eventDate ?? event.publishedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Published: ${_formatDate(event.publishedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}