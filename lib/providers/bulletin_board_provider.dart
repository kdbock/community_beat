import 'package:flutter/material.dart';
import '../models/post_item.dart';
import '../services/data_service.dart';

class BulletinBoardProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  
  bool _isLoading = false;
  String? _error;
  List<PostItem> _posts = [];
  String? _selectedCategory;
  final List<String> _categories = [
    'General',
    'Buy/Sell',
    'Jobs',
    'Lost & Found',
    'Volunteer',
  ];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PostItem> get posts => _posts;
  String? get selectedCategory => _selectedCategory;
  List<String> get categories => _categories;

  Future<void> fetchPosts() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch posts from Firestore
      final posts = await _dataService.getPosts();
      _posts = posts.map((post) => 
        PostItem(
          id: post.id,
          title: post.title,
          description: post.description,
          authorName: post.authorName,
          category: post.category,
          createdAt: post.createdAt,
          imageUrls: post.imageUrls.isNotEmpty ? post.imageUrls : null,
        )
      ).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadPosts() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch posts from Firestore
      final posts = await _dataService.getPosts();
      _posts = posts.map((post) => 
        PostItem(
          id: post.id,
          title: post.title,
          description: post.description,
          authorName: post.authorName,
          category: post.category,
          createdAt: post.createdAt,
          imageUrls: post.imageUrls.isNotEmpty ? post.imageUrls : null,
        )
      ).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void createPost(PostItem post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void deletePost(String postId) {
    _posts.removeWhere((post) => post.id == postId);
    notifyListeners();
  }
}
