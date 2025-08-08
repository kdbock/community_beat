class BusinessItem {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? phone;
  final String? email;
  final String? website;
  final String category;
  final double rating;
  final bool hasDeals;
  final bool isNew;
  final Function()? onTap;

  BusinessItem({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.phone,
    this.email,
    this.website,
    required this.category,
    required this.rating,
    this.hasDeals = false,
    this.isNew = false,
    this.onTap,
  });
}
