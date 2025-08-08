import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../services/data_service.dart';

class NewsEventsProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  
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
    return _eventDates.map((e) => e).toList();
  }

  Future<void> loadNews() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch news from Firestore
      final posts = await _dataService.getPosts();
      _news = posts.where((post) => post.type.toString().contains('general')).map((post) => 
        NewsItem(
          id: post.id,
          title: post.title,
          description: post.description,
          imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
          publishedAt: post.createdAt,
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

  Future<void> loadEvents() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch events from Firestore
      final events = await _dataService.getEvents();
      _events = events.map((event) => 
        NewsItem(
          id: event.id,
          title: event.title,
          description: event.description,
          imageUrl: event.imageUrls.isNotEmpty ? event.imageUrls.first : null,
          publishedAt: event.startDate,
          isEvent: true,
          eventDate: event.startDate,
        )
      ).toList();
      
      // Update event dates for calendar
      _eventDates = events.map((event) => event.startDate).toList();

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
