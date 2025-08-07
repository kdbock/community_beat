// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/index.dart';
import '../services/map_service.dart';
import '../providers/data_provider.dart';
import '../models/post.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  bool _showBusinesses = true;
  bool _showEvents = true;
  bool _showPosts = true;
  bool _isLoading = false;
  
  LatLng _currentPosition = MapService.defaultLocation;
  Set<Marker> _markers = {};
  final MapService _mapService = MapService();

  // Filter states
  String? _selectedBusinessCategory;
  String? _selectedEventCategory;
  String? _selectedPostCategory;
  PostType? _selectedPostType;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: const Text('Community Map'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.0,
            ),
            mapType: _currentMapType,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: (LatLng position) {
              CustomSnackBar.showInfo(
                context, 
                'Tapped at: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
              );
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll use our custom button
            zoomControlsEnabled: false, // We'll use our custom controls
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Search bar
          MapSearchBar(
            onSearch: _performSearch,
            onCurrentLocation: _centerOnCurrentLocation,
          ),
          
          // Map controls
          MapControls(
            currentMapType: _currentMapType,
            showBusinesses: _showBusinesses,
            showEvents: _showEvents,
            showServices: _showPosts,
            onRecenter: _centerOnCurrentLocation,
            onMapTypeChanged: (mapType) {
              setState(() {
                _currentMapType = mapType;
              });
            },
            onToggleBusinesses: (value) => _toggleLayer('businesses'),
            onToggleEvents: (value) => _toggleLayer('events'),
            onToggleServices: (value) => _toggleLayer('posts'),
          ),
          
          // Map legend
          const MapLegend(),
          
          // Refresh button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _refreshMarkers,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize data provider if not already done
      final dataProvider = context.read<DataProvider>();
      if (!dataProvider.isInitialized) {
        await dataProvider.initialize();
      }

      // Get current location
      final currentLocation = await _mapService.getCurrentLocation();
      if (currentLocation != null) {
        _currentPosition = currentLocation;
      }

      // Load initial markers
      await _loadMarkers();
    } catch (e) {
      CustomSnackBar.showError(context, 'Failed to initialize map: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMarkers() async {
    try {
      final markers = await _mapService.getAllMarkers(
        showBusinesses: _showBusinesses,
        showEvents: _showEvents,
        showPosts: _showPosts,
        businessCategory: _selectedBusinessCategory,
        eventCategory: _selectedEventCategory,
        postCategory: _selectedPostCategory,
        postType: _selectedPostType,
        userLocation: _currentPosition,
        radiusKm: 10.0, // 10km radius
      );

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      CustomSnackBar.showError(context, 'Failed to load markers: $e');
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentLocation = await _mapService.getCurrentLocation();
      if (currentLocation != null && _mapController != null) {
        _currentPosition = currentLocation;
        
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation,
              zoom: 16.0,
            ),
          ),
        );
        
        CustomSnackBar.showSuccess(context, 'Centered on current location');
        
        // Reload markers with new location
        await _loadMarkers();
      } else {
        CustomSnackBar.showWarning(context, 'Could not get current location');
      }
    } catch (e) {
      CustomSnackBar.showError(context, 'Failed to get location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMarkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh data in provider
      final dataProvider = context.read<DataProvider>();
      await dataProvider.refreshAllData();
      
      // Reload markers
      await _loadMarkers();
      
      CustomSnackBar.showSuccess(context, 'Map refreshed');
    } catch (e) {
      CustomSnackBar.showError(context, 'Failed to refresh map: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleLayer(String layer) {
    setState(() {
      switch (layer) {
        case 'businesses':
          _showBusinesses = !_showBusinesses;
          break;
        case 'events':
          _showEvents = !_showEvents;
          break;
        case 'posts':
          _showPosts = !_showPosts;
          break;
      }
    });
    
    _loadMarkers();
    CustomSnackBar.showInfo(context, 'Layer toggled: $layer');
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _mapService.searchLocations(query);
      
      if (results.isNotEmpty) {
        // Show search results dialog
        _showSearchResults(results);
      } else {
        CustomSnackBar.showInfo(context, 'No results found for "$query"');
      }
    } catch (e) {
      CustomSnackBar.showError(context, 'Search failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSearchResults(List<MapSearchResult> results) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Results (${results.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return ListTile(
                    leading: Icon(_getSearchResultIcon(result.type)),
                    title: Text(result.title),
                    subtitle: Text(result.subtitle),
                    onTap: () {
                      Navigator.pop(context);
                      _goToLocation(result.position);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSearchResultIcon(MapSearchResultType type) {
    switch (type) {
      case MapSearchResultType.business:
        return Icons.business;
      case MapSearchResultType.event:
        return Icons.event;
      case MapSearchResultType.post:
        return Icons.post_add;
      case MapSearchResultType.location:
        return Icons.location_on;
    }
  }

  Future<void> _goToLocation(LatLng position) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Filters'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Layer toggles
              CheckboxListTile(
                title: const Text('Show Businesses'),
                value: _showBusinesses,
                onChanged: (value) {
                  setState(() {
                    _showBusinesses = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Show Events'),
                value: _showEvents,
                onChanged: (value) {
                  setState(() {
                    _showEvents = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Show Posts'),
                value: _showPosts,
                onChanged: (value) {
                  setState(() {
                    _showPosts = value ?? true;
                  });
                },
              ),
              // Add category filters here if needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadMarkers();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return AlertDialog(
          title: const Text('Search Map'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Search for businesses, events, or locations...',
            ),
            onChanged: (value) {
              searchQuery = value;
            },
            onSubmitted: (value) {
              Navigator.pop(context);
              _performSearch(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSearch(searchQuery);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}