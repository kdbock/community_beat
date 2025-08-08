import 'package:flutter/material.dart';
import '../models/news_item.dart';

class NewsEventsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<NewsItem> _news = [];
  List<NewsItem> _events = [];
  DateTime? _selectedDate;
  List<DateTime> _eventDates = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NewsItem> get news => _news;
  List<NewsItem> get events => _events;
  DateTime? get selectedDate => _selectedDate;
  List<NewsItem> get newsItems => _news;

  List<DateTime> getEventDates() {
    return _eventDates.map((e) => e as DateTime).toList();
  }

  Future<void> loadNews() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Implement actual news fetching logic
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _news = []; // Replace with actual data

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEvents() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Implement actual events fetching logic
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _events = []; // Replace with actual data

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

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }
}
