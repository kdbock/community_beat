// lib/models/event.dart

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? address;
  final String? imageUrl;
  final List<String> imageUrls;
  final String category;
  final String organizer;
  final String? contactInfo;
  final bool isUrgent;
  final List<String> tags;
  final int? maxAttendees;
  final double? ticketPrice;
  final bool isRecurring;
  final String? recurringPattern;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.address,
    this.imageUrl,
    this.imageUrls = const [],
    required this.category,
    required this.organizer,
    this.contactInfo,
    this.isUrgent = false,
    this.tags = const [],
    this.maxAttendees,
    this.ticketPrice,
    this.isRecurring = false,
    this.recurringPattern,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'] ?? '',
      address: json['address'],
      imageUrl: json['image_url'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      category: json['category'] ?? '',
      organizer: json['organizer'] ?? '',
      contactInfo: json['contact_info'],
      isUrgent: json['is_urgent'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      maxAttendees: json['max_attendees'],
      ticketPrice: json['ticket_price']?.toDouble(),
      isRecurring: json['is_recurring'] ?? false,
      recurringPattern: json['recurring_pattern'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'address': address,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'category': category,
      'organizer': organizer,
      'contact_info': contactInfo,
      'is_urgent': isUrgent,
      'tags': tags,
      'max_attendees': maxAttendees,
      'ticket_price': ticketPrice,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? address,
    String? imageUrl,
    List<String>? imageUrls,
    String? category,
    String? organizer,
    String? contactInfo,
    bool? isUrgent,
    List<String>? tags,
    int? maxAttendees,
    double? ticketPrice,
    bool? isRecurring,
    String? recurringPattern,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      organizer: organizer ?? this.organizer,
      contactInfo: contactInfo ?? this.contactInfo,
      isUrgent: isUrgent ?? this.isUrgent,
      tags: tags ?? this.tags,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
    );
  }
}