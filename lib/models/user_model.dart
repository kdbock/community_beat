// lib/models/user_model.dart

enum UserRole {
  resident,
  businessOwner,
  admin,
  moderator,
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoURL;
  final UserRole role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final Map<String, dynamic> preferences;
  final List<String> interests;
  final String? address;
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.role = UserRole.resident,
    this.isActive = true,
    this.isEmailVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.preferences = const {},
    this.interests = const [],
    this.address,
    this.latitude,
    this.longitude,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      phoneNumber: json['phone_number'],
      photoURL: json['photo_url'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.resident,
      ),
      isActive: json['is_active'] ?? true,
      isEmailVerified: json['is_email_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      interests: List<String>.from(json['interests'] ?? []),
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'photo_url': photoURL,
      'role': role.toString().split('.').last,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'preferences': preferences,
      'interests': interests,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    UserRole? role,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    Map<String, dynamic>? preferences,
    List<String>? interests,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
      interests: interests ?? this.interests,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.resident:
        return 'Resident';
      case UserRole.businessOwner:
        return 'Business Owner';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.moderator:
        return 'Moderator';
    }
  }

  bool get canCreateBusiness => role == UserRole.businessOwner || role == UserRole.admin;
  bool get canModerateContent => role == UserRole.moderator || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  String get memberSince {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Member for ${years} year${years == 1 ? '' : 's'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Member for ${months} month${months == 1 ? '' : 's'}';
    } else if (difference.inDays > 0) {
      return 'Member for ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else {
      return 'New member';
    }
  }

  String? get lastSeenText {
    if (lastLogin == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(lastLogin!);
    
    if (difference.inMinutes < 5) {
      return 'Active now';
    } else if (difference.inHours < 1) {
      return 'Active ${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return 'Active ${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays} days ago';
    } else {
      return 'Last seen ${lastLogin!.month}/${lastLogin!.day}';
    }
  }
}