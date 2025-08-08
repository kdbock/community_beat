import 'package:flutter/material.dart';
import '../models/business_item.dart';

class BusinessDirectoryProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<BusinessItem> _businesses = [];
  String? _selectedCategory;
  String _searchQuery = '';
  final List<String> _categories = [
    'Food',
    'Shopping',
    'Services',
    'Entertainment',
  ];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<BusinessItem> get businesses => _businesses;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  List<String> get categories => _categories;

  /// Load businesses with optional filtering
  Future<void> loadBusinesses() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for demonstration
      _businesses = [
        BusinessItem(
          id: '1',
          name: 'Sample Restaurant',
          description: 'A cozy local restaurant',
          category: 'Food',
          rating: 4.5,
        ),
        BusinessItem(
          id: '2',
          name: 'Local Market',
          description: 'Fresh produce and groceries',
          category: 'Shopping',
          rating: 4.0,
        ),
        BusinessItem(
          id: '3',
          name: 'Community Salon',
          description: 'Professional hair and beauty services',
          category: 'Services',
          rating: 4.8,
        ),
        BusinessItem(
          id: '4',
          name: 'Movie Theater',
          description: 'Latest movies and entertainment',
          category: 'Entertainment',
          rating: 4.2,
        ),
      ];

      // Apply filters if any
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply search and category filters to the business list
  void _applyFilters() {
    var filteredList = List<BusinessItem>.from(_businesses);

    // Apply category filter if selected
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filteredList =
          filteredList
              .where((business) => business.category == _selectedCategory)
              .toList();
    }

    // Apply search filter if query exists
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredList =
          filteredList.where((business) {
            return business.name.toLowerCase().contains(query) ||
                business.description.toLowerCase().contains(query);
          }).toList();
    }

    _businesses = filteredList;
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set the search query and trigger a search
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set the selected category and filter businesses
  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }
}
