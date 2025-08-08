// lib/models/event.dart

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final String category;
  final String organizer;
  final String? contactInfo;
  final bool isUrgent;
  final List<String> tags;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.imageUrl,
    required this.category,
    required this.organizer,
    this.contactInfo,
    this.isUrgent = false,
    this.tags = const [],
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'] ?? '',
      imageUrl: json['image_url'],
      category: json['category'] ?? '',
      organizer: json['organizer'] ?? '',
      contactInfo: json['contact_info'],
      isUrgent: json['is_urgent'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
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
      'image_url': imageUrl,
      'category': category,
      'organizer': organizer,
      'contact_info': contactInfo,
      'is_urgent': isUrgent,
      'tags': tags,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    String? category,
    String? organizer,
    String? contactInfo,
    bool? isUrgent,
    List<String>? tags,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      organizer: organizer ?? this.organizer,
      contactInfo: contactInfo ?? this.contactInfo,
      isUrgent: isUrgent ?? this.isUrgent,
      tags: tags ?? this.tags,
    );
  }
}