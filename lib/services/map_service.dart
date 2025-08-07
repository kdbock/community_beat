// lib/services/map_service.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/business.dart';
import '../models/event.dart';
import '../models/post.dart';
import 'data_service.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final DataService _dataService = DataService();

  // Default location (you can change this to your community's center)
  static const LatLng defaultLocation = LatLng(40.7128, -74.0060); // New York City

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user location
  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Create markers for businesses
  Future<Set<Marker>> createBusinessMarkers({
    String? category,
    LatLng? userLocation,
    double? radiusKm,
  }) async {
    try {
      final businesses = await _dataService.getBusinesses(
        category: category,
        latitude: userLocation?.latitude,
        longitude: userLocation?.longitude,
        radiusKm: radiusKm,
      );

      return businesses.where((business) => 
        business.latitude != null && business.longitude != null
      ).map((business) => Marker(
        markerId: MarkerId('business_${business.id}'),
        position: LatLng(business.latitude!, business.longitude!),
        icon: await _getBusinessIcon(business.category),
        infoWindow: InfoWindow(
          title: business.name,
          snippet: '${business.category} • ${business.rating.toStringAsFixed(1)} ⭐',
          onTap: () => _onBusinessMarkerTapped(business),
        ),
      )).toSet();
    } catch (e) {
      debugPrint('Error creating business markers: $e');
      return {};
    }
  }

  /// Create markers for events
  Future<Set<Marker>> createEventMarkers({
    String? category,
    bool upcomingOnly = true,
  }) async {
    try {
      final events = await _dataService.getEvents(
        category: category,
        upcomingOnly: upcomingOnly,
      );

      Set<Marker> markers = {};
      
      for (final event in events) {
        // For events without coordinates, try to geocode the location
        LatLng? position = await _geocodeEventLocation(event);
        
        if (position != null) {
          markers.add(Marker(
            markerId: MarkerId('event_${event.id}'),
            position: position,
            icon: await _getEventIcon(event.category),
            infoWindow: InfoWindow(
              title: event.title,
              snippet: '${event.category} • ${_formatEventDate(event.startDate)}',
              onTap: () => _onEventMarkerTapped(event),
            ),
          ));
        }
      }

      return markers;
    } catch (e) {
      debugPrint('Error creating event markers: $e');
      return {};
    }
  }

  /// Create markers for posts with location
  Future<Set<Marker>> createPostMarkers({
    String? category,
    PostType? type,
  }) async {
    try {
      final posts = await _dataService.getPosts(
        category: category,
        type: type,
      );

      Set<Marker> markers = {};
      
      for (final post in posts.where((p) => p.location != null)) {
        // Try to geocode the post location
        LatLng? position = await _geocodePostLocation(post);
        
        if (position != null) {
          markers.add(Marker(
            markerId: MarkerId('post_${post.id}'),
            position: position,
            icon: await _getPostIcon(post.type),
            infoWindow: InfoWindow(
              title: post.title,
              snippet: '${post.typeDisplayName} • ${post.timeAgo}',
              onTap: () => _onPostMarkerTapped(post),
            ),
          ));
        }
      }

      return markers;
    } catch (e) {
      debugPrint('Error creating post markers: $e');
      return {};
    }
  }

  /// Get all markers for the map
  Future<Set<Marker>> getAllMarkers({
    bool showBusinesses = true,
    bool showEvents = true,
    bool showPosts = true,
    String? businessCategory,
    String? eventCategory,
    String? postCategory,
    PostType? postType,
    LatLng? userLocation,
    double? radiusKm,
  }) async {
    Set<Marker> allMarkers = {};

    final futures = <Future<Set<Marker>>>[];

    if (showBusinesses) {
      futures.add(createBusinessMarkers(
        category: businessCategory,
        userLocation: userLocation,
        radiusKm: radiusKm,
      ));
    }

    if (showEvents) {
      futures.add(createEventMarkers(category: eventCategory));
    }

    if (showPosts) {
      futures.add(createPostMarkers(
        category: postCategory,
        type: postType,
      ));
    }

    final results = await Future.wait(futures);
    
    for (final markerSet in results) {
      allMarkers.addAll(markerSet);
    }

    return allMarkers;
  }

  /// Search for locations
  Future<List<MapSearchResult>> searchLocations(String query) async {
    try {
      final results = await _dataService.globalSearch(query);
      List<MapSearchResult> searchResults = [];

      // Add businesses to search results
      for (final business in results['businesses'] as List<Business>) {
        if (business.latitude != null && business.longitude != null) {
          searchResults.add(MapSearchResult(
            id: business.id,
            title: business.name,
            subtitle: business.category,
            position: LatLng(business.latitude!, business.longitude!),
            type: MapSearchResultType.business,
            data: business,
          ));
        }
      }

      // Add events to search results
      for (final event in results['events'] as List<Event>) {
        final position = await _geocodeEventLocation(event);
        if (position != null) {
          searchResults.add(MapSearchResult(
            id: event.id,
            title: event.title,
            subtitle: event.category,
            position: position,
            type: MapSearchResultType.event,
            data: event,
          ));
        }
      }

      return searchResults;
    } catch (e) {
      debugPrint('Error searching locations: $e');
      return [];
    }
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert to kilometers
  }

  // Private helper methods

  Future<BitmapDescriptor> _getBusinessIcon(String category) async {
    // You can customize icons based on business category
    switch (category.toLowerCase()) {
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'retail':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'healthcare':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'automotive':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<BitmapDescriptor> _getEventIcon(String category) async {
    // You can customize icons based on event category
    switch (category.toLowerCase()) {
      case 'entertainment':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'government':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'sports':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  Future<BitmapDescriptor> _getPostIcon(PostType type) async {
    // You can customize icons based on post type
    switch (type) {
      case PostType.buySell:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case PostType.job:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case PostType.housing:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case PostType.lostFound:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
  }

  Future<LatLng?> _geocodeEventLocation(Event event) async {
    // In a real app, you would use a geocoding service to convert
    // the event location string to coordinates
    // For now, we'll use some sample coordinates based on common locations
    return _geocodeLocationString(event.location);
  }

  Future<LatLng?> _geocodePostLocation(Post post) async {
    if (post.location == null) return null;
    return _geocodeLocationString(post.location!);
  }

  Future<LatLng?> _geocodeLocationString(String location) async {
    // Simple geocoding simulation - in a real app, use Google Geocoding API
    final locationLower = location.toLowerCase();
    
    // Sample locations - replace with actual geocoding
    if (locationLower.contains('downtown') || locationLower.contains('main street')) {
      return const LatLng(40.7128, -74.0060);
    } else if (locationLower.contains('central park') || locationLower.contains('park')) {
      return const LatLng(40.7829, -73.9654);
    } else if (locationLower.contains('city hall') || locationLower.contains('government')) {
      return const LatLng(40.7127, -74.0059);
    } else if (locationLower.contains('community center')) {
      return const LatLng(40.7589, -73.9851);
    }
    
    // Return a random nearby location if we can't geocode
    return LatLng(
      defaultLocation.latitude + (0.01 * (DateTime.now().millisecond % 100 - 50) / 50),
      defaultLocation.longitude + (0.01 * (DateTime.now().microsecond % 100 - 50) / 50),
    );
  }

  void _onBusinessMarkerTapped(Business business) {
    // Handle business marker tap - could navigate to business detail screen
    debugPrint('Business marker tapped: ${business.name}');
  }

  void _onEventMarkerTapped(Event event) {
    // Handle event marker tap - could navigate to event detail screen
    debugPrint('Event marker tapped: ${event.title}');
  }

  void _onPostMarkerTapped(Post post) {
    // Handle post marker tap - could navigate to post detail screen
    debugPrint('Post marker tapped: ${post.title}');
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';
    
    return '${date.month}/${date.day}';
  }
}

/// Map search result model
class MapSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final LatLng position;
  final MapSearchResultType type;
  final dynamic data;

  MapSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.position,
    required this.type,
    this.data,
  });
}

enum MapSearchResultType {
  business,
  event,
  post,
  location,
}