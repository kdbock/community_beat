import 'package:flutter/material.dart';

/// Main app state provider using Provider package
class AppStateProvider extends ChangeNotifier {
  int _currentBottomNavIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _userData = {};

  // Getters
  int get currentBottomNavIndex => _currentBottomNavIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get userData => _userData;

  // Navigation
  void setBottomNavIndex(int index) {
    _currentBottomNavIndex = index;
    notifyListeners();
  }

  // Loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error handling
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // User data
  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void clearUserData() {
    _userData = {};
    notifyListeners();
  }
}

/// News and Events provider
class NewsEventsProvider extends ChangeNotifier {
  List<NewsEventItem> _newsItems = [];
  List<NewsEventItem> _eventItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDate;

  // Getters
  List<NewsEventItem> get newsItems => _newsItems;
  List<NewsEventItem> get eventItems => _eventItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get selectedDate => _selectedDate;

  // Methods
  Future<void> loadNews() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _newsItems = []; // Load from API
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _eventItems = []; // Load from API
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  List<DateTime> getEventDates() {
    return _eventItems
        .where((item) => item.eventDate != null)
        .map((item) => item.eventDate!)
        .toList();
  }
}

/// Business Directory provider
class BusinessDirectoryProvider extends ChangeNotifier {
  List<BusinessItem> _businesses = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BusinessItem> get businesses => _filteredBusinesses;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BusinessItem> get _filteredBusinesses {
    var filtered = _businesses;

    if (_selectedCategory != null) {
      filtered = filtered.where((b) => b.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) => 
        b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        b.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  // Methods
  Future<void> loadBusinesses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _businesses = []; // Load from API
      _categories = []; // Load categories
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

/// Bulletin Board provider
class BulletinBoardProvider extends ChangeNotifier {
  List<PostItem> _posts = [];
  final List<String> _categories = ['Jobs', 'Sell', 'Buy', 'Services', 'Events', 'General'];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<PostItem> get posts => _filteredPosts;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PostItem> get _filteredPosts {
    if (_selectedCategory == null) return _posts;
    return _posts.where((p) => p.category == _selectedCategory).toList();
  }

  // Methods
  Future<void> loadPosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _posts = []; // Load from API
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createPost(PostItem post) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _posts.insert(0, post);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }
}

// Data models
class NewsEventItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime publishedAt;
  final bool isEvent;
  final DateTime? eventDate;

  NewsEventItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.publishedAt,
    this.isEvent = false,
    this.eventDate,
  });
}

class BusinessItem {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? phone;
  final String? email;
  final String category;
  final double? rating;
  final bool hasDeals;
  final bool isNew;

  BusinessItem({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.phone,
    this.email,
    required this.category,
    this.rating,
    this.hasDeals = false,
    this.isNew = false,
  });
}

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