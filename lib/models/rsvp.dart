// lib/models/rsvp.dart

class RSVP {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime rsvpDate;
  final RSVPStatus status;
  final int? partySize;
  final String? notes;

  RSVP({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rsvpDate,
    required this.status,
    this.partySize,
    this.notes,
  });

  factory RSVP.fromJson(Map<String, dynamic> json) {
    return RSVP(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      rsvpDate: DateTime.parse(json['rsvp_date']),
      status: RSVPStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RSVPStatus.going,
      ),
      partySize: json['party_size'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'rsvp_date': rsvpDate.toIso8601String(),
      'status': status.name,
      'party_size': partySize,
      'notes': notes,
    };
  }

  RSVP copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? rsvpDate,
    RSVPStatus? status,
    int? partySize,
    String? notes,
  }) {
    return RSVP(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      rsvpDate: rsvpDate ?? this.rsvpDate,
      status: status ?? this.status,
      partySize: partySize ?? this.partySize,
      notes: notes ?? this.notes,
    );
  }
}

enum RSVPStatus {
  going,
  notGoing,
  maybe,
  cancelled,
}

extension RSVPStatusExtension on RSVPStatus {
  String get displayName {
    switch (this) {
      case RSVPStatus.going:
        return 'Going';
      case RSVPStatus.notGoing:
        return 'Not Going';
      case RSVPStatus.maybe:
        return 'Maybe';
      case RSVPStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case RSVPStatus.going:
        return '✅';
      case RSVPStatus.notGoing:
        return '❌';
      case RSVPStatus.maybe:
        return '❓';
      case RSVPStatus.cancelled:
        return '🚫';
    }
  }
}