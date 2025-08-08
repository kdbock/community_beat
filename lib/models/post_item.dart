class PostItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String authorName;
  final DateTime createdAt;
  final List<String>? imageUrls;

  PostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.authorName,
    required this.createdAt,
    this.imageUrls,
  });
}
