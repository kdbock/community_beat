import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Floating controls for map functionality
class MapControls extends StatelessWidget {
  final VoidCallback? onRecenter;
  final Function(MapType)? onMapTypeChanged;
  final Function(bool)? onToggleBusinesses;
  final Function(bool)? onToggleEvents;
  final Function(bool)? onToggleServices;
  final MapType currentMapType;
  final bool showBusinesses;
  final bool showEvents;
  final bool showServices;

  const MapControls({
    super.key,
    this.onRecenter,
    this.onMapTypeChanged,
    this.onToggleBusinesses,
    this.onToggleEvents,
    this.onToggleServices,
    this.currentMapType = MapType.normal,
    this.showBusinesses = true,
    this.showEvents = true,
    this.showServices = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          // Map type toggle
          FloatingActionButton(
            mini: true,
            heroTag: "mapType",
            onPressed: () => _showMapTypeDialog(context),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.layers),
          ),
          const SizedBox(height: 8),
          // Layer toggle
          FloatingActionButton(
            mini: true,
            heroTag: "layers",
            onPressed: () => _showLayerDialog(context),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.filter_list),
          ),
          const SizedBox(height: 8),
          // Recenter button
          if (onRecenter != null)
            FloatingActionButton(
              mini: true,
              heroTag: "recenter",
              onPressed: onRecenter,
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.my_location),
            ),
        ],
      ),
    );
  }

  void _showMapTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMapTypeOption(context, MapType.normal, 'Normal', Icons.map),
            _buildMapTypeOption(context, MapType.satellite, 'Satellite', Icons.satellite),
            _buildMapTypeOption(context, MapType.hybrid, 'Hybrid', Icons.layers),
            _buildMapTypeOption(context, MapType.terrain, 'Terrain', Icons.terrain),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(BuildContext context, MapType type, String label, IconData icon) {
    final isSelected = currentMapType == type;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () {
        Navigator.of(context).pop();
        onMapTypeChanged?.call(type);
      },
    );
  }

  void _showLayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Layers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Businesses'),
              subtitle: const Text('Show business locations'),
              value: showBusinesses,
              onChanged: (value) {
                Navigator.of(context).pop();
                onToggleBusinesses?.call(value);
              },
            ),
            SwitchListTile(
              title: const Text('Events'),
              subtitle: const Text('Show event locations'),
              value: showEvents,
              onChanged: (value) {
                Navigator.of(context).pop();
                onToggleEvents?.call(value);
              },
            ),
            SwitchListTile(
              title: const Text('Services'),
              subtitle: const Text('Show public services'),
              value: showServices,
              onChanged: (value) {
                Navigator.of(context).pop();
                onToggleServices?.call(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Custom map markers for different types
class CustomMapMarkers {
  static BitmapDescriptor? _businessIcon;
  static BitmapDescriptor? _eventIcon;
  static BitmapDescriptor? _serviceIcon;

  static Future<void> loadCustomMarkers() async {
    try {
      _businessIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/business_marker.png',
      );
    } catch (_) {
      _businessIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }

    try {
      _eventIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/event_marker.png',
      );
    } catch (_) {
      _eventIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    try {
      _serviceIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/service_marker.png',
      );
    } catch (_) {
      _serviceIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  static BitmapDescriptor getBusinessIcon() {
    return _businessIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  static BitmapDescriptor getEventIcon() {
    return _eventIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  static BitmapDescriptor getServiceIcon() {
    return _serviceIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }
}

/// Map legend widget
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 100,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legend',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Icons.business, 'Businesses', Colors.blue),
            _buildLegendItem(Icons.event, 'Events', Colors.red),
            _buildLegendItem(Icons.account_balance, 'Services', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}