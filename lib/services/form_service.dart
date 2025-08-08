// lib/services/form_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/post.dart';
import '../models/event.dart';
import '../models/service_request.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class FormService {
  static final FormService _instance = FormService._internal();
  factory FormService() => _instance;
  FormService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Draft keys
  static const String _postDraftKey = 'post_draft';
  static const String _eventDraftKey = 'event_draft';
  static const String _serviceRequestDraftKey = 'service_request_draft';

  /// Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/${user.uid}/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw FormException('Failed to upload image: $e');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles, String folder) async {
    try {
      final futures = imageFiles.map((file) => uploadImage(file, folder));
      return await Future.wait(futures);
    } catch (e) {
      throw FormException('Failed to upload images: $e');
    }
  }

  /// Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw FormException('Failed to pick image: $e');
    }
  }

  /// Pick multiple images
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFiles.length > maxImages) {
        throw FormException('Maximum $maxImages images allowed');
      }
      
      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      throw FormException('Failed to pick images: $e');
    }
  }

  /// Pick file
  Future<File?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw FormException('Failed to pick file: $e');
    }
  }

  /// Show image source selection dialog
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final image = await pickImage(source: ImageSource.camera);
                Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await pickImage(source: ImageSource.gallery);
                Navigator.pop(context, image);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // DRAFT MANAGEMENT

  /// Save post draft
  Future<void> savePostDraft(PostDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return;
      
      final key = '${_postDraftKey}_${user.uid}';
      await prefs.setString(key, jsonEncode(draft.toJson()));
    } catch (e) {
      debugPrint('Failed to save post draft: $e');
    }
  }

  /// Load post draft
  Future<PostDraft?> loadPostDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return null;
      
      final key = '${_postDraftKey}_${user.uid}';
      final draftJson = prefs.getString(key);
      
      if (draftJson != null) {
        return PostDraft.fromJson(jsonDecode(draftJson));
      }
      return null;
    } catch (e) {
      debugPrint('Failed to load post draft: $e');
      return null;
    }
  }

  /// Clear post draft
  Future<void> clearPostDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return;
      
      final key = '${_postDraftKey}_${user.uid}';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Failed to clear post draft: $e');
    }
  }

  /// Save event draft
  Future<void> saveEventDraft(EventDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return;
      
      final key = '${_eventDraftKey}_${user.uid}';
      await prefs.setString(key, jsonEncode(draft.toJson()));
    } catch (e) {
      debugPrint('Failed to save event draft: $e');
    }
  }

  /// Load event draft
  Future<EventDraft?> loadEventDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return null;
      
      final key = '${_eventDraftKey}_${user.uid}';
      final draftJson = prefs.getString(key);
      
      if (draftJson != null) {
        return EventDraft.fromJson(jsonDecode(draftJson));
      }
      return null;
    } catch (e) {
      debugPrint('Failed to load event draft: $e');
      return null;
    }
  }

  /// Clear event draft
  Future<void> clearEventDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return;
      
      final key = '${_eventDraftKey}_${user.uid}';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Failed to clear event draft: $e');
    }
  }

  /// Save service request draft
  Future<void> saveServiceRequestDraft(ServiceRequestDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return;
      
      final key = '${_serviceRequestDraftKey}_${user.uid}';
      await prefs.setString(key, jsonEncode(draft.toJson()));
    } catch (e) {
      debugPrint('Failed to save service request draft: $e');
    }
  }

  /// Load service request draft
  Future<ServiceRequestDraft?> loadServiceRequestDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return null;
      
      final key = '${_serviceRequestDraftKey}_${user.uid}';
      final draftJson = prefs.getString(key);
      
      if (draftJson != null) {
        return ServiceRequestDraft.fromJson(jsonDecode(draftJson));
      }
      return null;
    } catch (e) {
      debugPrint('Failed to load service request draft: $e');
      return null;
    }
  }

  /// Clear service request draft
  Future<void> clearServiceRequestDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _authService.currentUser;
      if (user == null) return;
      
      final key = '${_serviceRequestDraftKey}_${user.uid}';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Failed to clear service request draft: $e');
    }
  }

  // FORM SUBMISSION

  /// Submit post form
  Future<Post> submitPost(PostDraft draft) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw FormException('User not authenticated');

      // Upload images if any
      List<String> imageUrls = [];
      if (draft.imageFiles.isNotEmpty) {
        imageUrls = await uploadImages(draft.imageFiles, 'posts');
      }

      // Create post
      final post = Post(
        id: '', // Will be set by Firestore
        title: draft.title,
        description: draft.content, // Use content as description
        type: draft.type,
        category: draft.category,
        authorName: user.displayName ?? 'Anonymous',
        authorContact: draft.contactInfo?['email'],
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
        location: draft.location,
        price: draft.price,
        tags: draft.tags,
        isActive: true,
        viewCount: 0,
      );

      // Save to Firestore
      final createdPost = await _firestoreService.createPost(post);
      
      // Clear draft
      await clearPostDraft();
      
      return createdPost;
    } catch (e) {
      throw FormException('Failed to submit post: $e');
    }
  }

  /// Submit event form
  Future<Event> submitEvent(EventDraft draft) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw FormException('User not authenticated');

      // Upload images if any
      List<String> imageUrls = [];
      if (draft.imageFiles.isNotEmpty) {
        imageUrls = await uploadImages(draft.imageFiles, 'events');
      }

      // Create event
      final event = Event(
        id: '', // Will be set by Firestore
        title: draft.title,
        description: draft.description,
        startDate: draft.startDate,
        endDate: draft.endDate,
        location: draft.location,
        address: draft.address,
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
        imageUrls: imageUrls,
        category: draft.category,
        organizer: user.displayName ?? 'Anonymous',
        contactInfo: user.email,
        isUrgent: false, // Events don't have urgent flag like service requests
        tags: draft.tags,
        maxAttendees: draft.maxAttendees,
        ticketPrice: draft.ticketPrice,
        isRecurring: draft.isRecurring,
        recurringPattern: draft.recurringPattern,
      );

      // Save to Firestore
      final createdEvent = await _firestoreService.createEvent(event);
      
      // Clear draft
      await clearEventDraft();
      
      return createdEvent;
    } catch (e) {
      throw FormException('Failed to submit event: $e');
    }
  }

  /// Submit service request form
  Future<ServiceRequest> submitServiceRequest(ServiceRequestDraft draft) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw FormException('User not authenticated');

      // Upload images if any
      List<String> imageUrls = [];
      if (draft.imageFiles.isNotEmpty) {
        imageUrls = await uploadImages(draft.imageFiles, 'service_requests');
      }

      // Create service request
      final serviceRequest = ServiceRequest(
        id: '', // Will be set by Firestore
        title: draft.title,
        description: draft.description,
        category: draft.category,
        priority: draft.priority,
        requesterId: user.uid,
        requesterName: user.displayName ?? 'Anonymous',
        requesterAvatar: user.photoURL,
        location: draft.location,
        address: draft.address,
        contactInfo: draft.contactInfo,
        imageUrls: imageUrls,
        preferredDate: draft.preferredDate,
        tags: draft.tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ServiceRequestStatus.open,
        isUrgent: draft.isUrgent,
      );

      // Save to Firestore
      final createdRequest = await _firestoreService.createServiceRequest(serviceRequest);
      
      // Clear draft
      await clearServiceRequestDraft();
      
      return createdRequest;
    } catch (e) {
      throw FormException('Failed to submit service request: $e');
    }
  }

  /// Validate image file
  bool isValidImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Get image file size in MB
  double getImageSizeMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }

  /// Validate image size (max 10MB)
  bool isValidImageSize(File file, {double maxSizeMB = 10.0}) {
    return getImageSizeMB(file) <= maxSizeMB;
  }
}

/// Custom exception for form operations
class FormException implements Exception {
  final String message;
  FormException(this.message);

  @override
  String toString() => 'FormException: $message';
}

/// Draft models for saving form state

class PostDraft {
  final String title;
  final String content;
  final PostType type;
  final String category;
  final List<File> imageFiles;
  final String? location;
  final double? price;
  final Map<String, String>? contactInfo;
  final List<String> tags;
  final DateTime savedAt;

  PostDraft({
    required this.title,
    required this.content,
    required this.type,
    required this.category,
    this.imageFiles = const [],
    this.location,
    this.price,
    this.contactInfo,
    this.tags = const [],
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type.toString(),
      'category': category,
      'image_paths': imageFiles.map((f) => f.path).toList(),
      'location': location,
      'price': price,
      'contact_info': contactInfo,
      'tags': tags,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory PostDraft.fromJson(Map<String, dynamic> json) {
    return PostDraft(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PostType.general,
      ),
      category: json['category'] ?? '',
      imageFiles: (json['image_paths'] as List<dynamic>?)
          ?.map((path) => File(path))
          .toList() ?? [],
      location: json['location'],
      price: json['price']?.toDouble(),
      contactInfo: json['contact_info'] != null
          ? Map<String, String>.from(json['contact_info'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      savedAt: DateTime.parse(json['saved_at']),
    );
  }
}

class EventDraft {
  final String title;
  final String description;
  final String category;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? address;
  final List<File> imageFiles;
  final int? maxAttendees;
  final double? ticketPrice;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime savedAt;

  EventDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    this.endDate,
    required this.location,
    this.address,
    this.imageFiles = const [],
    this.maxAttendees,
    this.ticketPrice,
    this.tags = const [],
    this.isRecurring = false,
    this.recurringPattern,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'address': address,
      'image_paths': imageFiles.map((f) => f.path).toList(),
      'max_attendees': maxAttendees,
      'ticket_price': ticketPrice,
      'tags': tags,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory EventDraft.fromJson(Map<String, dynamic> json) {
    return EventDraft(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'] ?? '',
      address: json['address'],
      imageFiles: (json['image_paths'] as List<dynamic>?)
          ?.map((path) => File(path))
          .toList() ?? [],
      maxAttendees: json['max_attendees'],
      ticketPrice: json['ticket_price']?.toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      isRecurring: json['is_recurring'] ?? false,
      recurringPattern: json['recurring_pattern'],
      savedAt: DateTime.parse(json['saved_at']),
    );
  }
}

class ServiceRequestDraft {
  final String title;
  final String description;
  final String category;
  final ServiceRequestPriority priority;
  final String? location;
  final String? address;
  final Map<String, String>? contactInfo;
  final List<File> imageFiles;
  final DateTime? preferredDate;
  final List<String> tags;
  final bool isUrgent;
  final DateTime savedAt;

  ServiceRequestDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.location,
    this.address,
    this.contactInfo,
    this.imageFiles = const [],
    this.preferredDate,
    this.tags = const [],
    this.isUrgent = false,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.toString(),
      'location': location,
      'address': address,
      'contact_info': contactInfo,
      'image_paths': imageFiles.map((f) => f.path).toList(),
      'preferred_date': preferredDate?.toIso8601String(),
      'tags': tags,
      'is_urgent': isUrgent,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory ServiceRequestDraft.fromJson(Map<String, dynamic> json) {
    return ServiceRequestDraft(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: ServiceRequestPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => ServiceRequestPriority.medium,
      ),
      location: json['location'],
      address: json['address'],
      contactInfo: json['contact_info'] != null
          ? Map<String, String>.from(json['contact_info'])
          : null,
      imageFiles: (json['image_paths'] as List<dynamic>?)
          ?.map((path) => File(path))
          .toList() ?? [],
      preferredDate: json['preferred_date'] != null
          ? DateTime.parse(json['preferred_date'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      isUrgent: json['is_urgent'] ?? false,
      savedAt: DateTime.parse(json['saved_at']),
    );
  }
}