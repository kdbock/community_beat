import 'package:flutter/material.dart';
import '../models/post_item.dart';

class BulletinBoardProvider extends ChangeNotifier {
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

      // TODO: Implement actual post fetching logic
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _posts = []; // Replace with actual data

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

      // TODO: Implement actual post fetching logic
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _posts = []; // Replace with actual data

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
