// lib/models/business.dart

class Business {
  final String id;
  final String name;
  final String description;
  final String category;
  final String address;
  final String phone;
  final String? email;
  final String? website;
  final Map<String, String> hours; // day -> hours (e.g., "Monday" -> "9:00 AM - 5:00 PM")
  final List<String> imageUrls;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final List<String> services;
  final bool isVerified;
  final bool isNew;
  final double? latitude;
  final double? longitude;
  final List<Deal> deals;

  Business({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.phone,
    this.email,
    this.website,
    this.hours = const {},
    this.imageUrls = const [],
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.services = const [],
    this.isVerified = false,
    this.isNew = false,
    this.latitude,
    this.longitude,
    this.deals = const [],
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      website: json['website'],
      hours: Map<String, String>.from(json['hours'] ?? {}),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      imageUrl: json['image_url'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      services: List<String>.from(json['services'] ?? []),
      isVerified: json['is_verified'] ?? false,
      isNew: json['is_new'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      deals: (json['deals'] as List<dynamic>?)
          ?.map((deal) => Deal.fromJson(deal))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'hours': hours,
      'image_urls': imageUrls,
      'image_url': imageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'services': services,
      'is_verified': isVerified,
      'is_new': isNew,
      'latitude': latitude,
      'longitude': longitude,
      'deals': deals.map((deal) => deal.toJson()).toList(),
    };
  }

  String get hoursToday {
    final today = DateTime.now().weekday;
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = dayNames[today - 1];
    return hours[todayName] ?? 'Hours not available';
  }

  bool get isOpenNow {
    // Simplified logic - in real app, you'd parse hours and check current time
    return hours.isNotEmpty;
  }
}

class Deal {
  final String id;
  final String title;
  final String description;
  final String? discountPercentage;
  final DateTime? expiryDate;
  final String? promoCode;

  Deal({
    required this.id,
    required this.title,
    required this.description,
    this.discountPercentage,
    this.expiryDate,
    this.promoCode,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discountPercentage: json['discount_percentage'],
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      promoCode: json['promo_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discount_percentage': discountPercentage,
      'expiry_date': expiryDate?.toIso8601String(),
      'promo_code': promoCode,
    };
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}