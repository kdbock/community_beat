import 'package:flutter/material.dart';

/// A basic location picker widget (to be enhanced with maps later)
class LocationPicker extends StatelessWidget {
  final String? selectedLocation;
  final Function(String) onLocationSelected;
  final String? hintText;

  const LocationPicker({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showLocationPicker(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedLocation ?? hintText ?? 'Select location',
                style: TextStyle(
                  color: selectedLocation != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    // For now, show a simple dialog. This can be enhanced with Google Maps later
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: selectedLocation ?? '');
        
        return AlertDialog(
          title: const Text('Enter Location'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter location name or address',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final location = controller.text.trim();
                if (location.isNotEmpty) {
                  onLocationSelected(location);
                }
                Navigator.pop(context);
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }
}
