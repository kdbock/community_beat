class NewsItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime publishedAt;
  final bool isEvent;
  final DateTime? eventDate;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.publishedAt,
    this.isEvent = false,
    this.eventDate,
  });
}
