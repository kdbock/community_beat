// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/index.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  final bool _showBusinesses = true;
  final bool _showEvents = true;
  final bool _showServices = true;
  
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194); // San Francisco
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
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
            icon: const Icon(Icons.search),
            onPressed: () {
              CustomSnackBar.showInfo(context, 'Search feature coming soon!');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main map
          CustomMap(
            initialPosition: _initialPosition,
            markers: _markers,
            mapType: _currentMapType,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onMapTapped: (position) {
              CustomSnackBar.showInfo(
                context, 
                'Tapped at: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
              );
            },
          ),
          // Search bar
          MapSearchBar(
            onSearch: (query) {
              CustomSnackBar.showInfo(context, 'Searching for: $query');
            },
            onCurrentLocation: () {
              _centerOnCurrentLocation();
            },
          ),
          // Map controls
          MapControls(
            currentMapType: _currentMapType,
            showBusinesses: _showBusinesses,
            showEvents: _showEvents,
            showServices: _showServices,
            onRecenter: () {
              _centerOnCurrentLocation();
            },
            onMapTypeChanged: (mapType) {
              setState(() {
                _currentMapType = mapType;
              });
            },
            onToggleLayer: (show) {
              // Handle layer toggle
              CustomSnackBar.showInfo(context, 'Layer toggled');
            },
          ),
          // Map legend
          const MapLegend(),
        ],
      ),
    );
  }

  void _loadMarkers() {
    // Sample markers
    _markers = {
      const Marker(
        markerId: MarkerId('business1'),
        position: LatLng(37.7849, -122.4094),
        infoWindow: InfoWindow(
          title: 'Joe\'s Pizza',
          snippet: 'Best pizza in town!',
        ),
      ),
      const Marker(
        markerId: MarkerId('event1'),
        position: LatLng(37.7649, -122.4194),
        infoWindow: InfoWindow(
          title: 'Summer Festival',
          snippet: 'Join us for music and food!',
        ),
      ),
      const Marker(
        markerId: MarkerId('service1'),
        position: LatLng(37.7749, -122.4294),
        infoWindow: InfoWindow(
          title: 'City Hall',
          snippet: 'Municipal services',
        ),
      ),
    };
    setState(() {});
  }

  void _centerOnCurrentLocation() {
    // In a real app, you would get the user's actual location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialPosition,
            zoom: 16.0,
          ),
        ),
      );
      CustomSnackBar.showInfo(context, 'Centered on current location');
    }
  }
}