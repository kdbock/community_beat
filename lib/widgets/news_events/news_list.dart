import 'package:flutter/material.dart';
import 'news_card.dart';

/// ListView widget for displaying news and alerts
class NewsList extends StatelessWidget {
  final List<NewsItem> newsItems;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final ScrollController? scrollController;

  const NewsList({
    super.key,
    required this.newsItems,
    this.isLoading = false,
    this.onRefresh,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && newsItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (newsItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No news available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    Widget listView = ListView.builder(
      controller: scrollController,
      itemCount: newsItems.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == newsItems.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = newsItems[index];
        return NewsCard(
          title: item.title,
          description: item.description,
          imageUrl: item.imageUrl,
          publishedAt: item.publishedAt,
          isEvent: item.isEvent,
          eventDate: item.eventDate,
          onTap: () => item.onTap?.call(),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          onRefresh!();
        },
        child: listView,
      );
    }

    return listView;
  }
}

/// Data model for news items
class NewsItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime publishedAt;
  final bool isEvent;
  final DateTime? eventDate;
  final VoidCallback? onTap;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.publishedAt,
    this.isEvent = false,
    this.eventDate,
    this.onTap,
  });
}