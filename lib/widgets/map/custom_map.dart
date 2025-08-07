import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Custom map widget with markers and info windows
class CustomMap extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Function(LatLng)? onMapTapped;
  final Function(Marker)? onMarkerTapped;
  final Function(GoogleMapController)? onMapCreated;
  final MapType mapType;
  final bool showMyLocation;
  final bool showMyLocationButton;

  const CustomMap({
    super.key,
    required this.initialPosition,
    this.markers = const {},
    this.onMapTapped,
    this.onMarkerTapped,
    this.onMapCreated,
    this.mapType = MapType.normal,
    this.showMyLocation = true,
    this.showMyLocationButton = true,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers = widget.markers;
  }

  @override
  void didUpdateWidget(CustomMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      setState(() {
        _markers = widget.markers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: 14.0,
      ),
      markers: _markers,
      onTap: widget.onMapTapped,
      mapType: widget.mapType,
      myLocationEnabled: widget.showMyLocation,
      myLocationButtonEnabled: widget.showMyLocationButton,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  Future<void> animateToPosition(LatLng position, {double zoom = 16.0}) async {
    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: zoom),
        ),
      );
    }
  }

  Future<void> fitBounds(LatLngBounds bounds) async {
    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }
}

/// Custom info window widget
class CustomInfoWindow extends StatelessWidget {
  final String title;
  final String? description;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const CustomInfoWindow({
    super.key,
    required this.title,
    this.description,
    this.imageUrl,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                imageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(Icons.close, size: 16),
                      ),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (onTap != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}