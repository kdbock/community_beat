import 'package:flutter/material.dart';

/// Search bar widget for map locations
class MapSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function()? onCurrentLocation;
  final List<SearchSuggestion>? suggestions;
  final Function(SearchSuggestion)? onSuggestionTapped;

  const MapSearchBar({
    super.key,
    required this.onSearch,
    this.onCurrentLocation,
    this.suggestions,
    this.onSuggestionTapped,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && 
                          widget.suggestions != null && 
                          widget.suggestions!.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search locations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch('');
                        setState(() {
                          _showSuggestions = false;
                        });
                      },
                    ),
                  if (widget.onCurrentLocation != null)
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: widget.onCurrentLocation,
                      tooltip: 'Current Location',
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              widget.onSearch(value);
              setState(() {
                _showSuggestions = value.isNotEmpty && 
                                 widget.suggestions != null && 
                                 widget.suggestions!.isNotEmpty;
              });
            },
            onSubmitted: (value) {
              _focusNode.unfocus();
              setState(() {
                _showSuggestions = false;
              });
            },
          ),
        ),
        if (_showSuggestions && widget.suggestions != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.suggestions!.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions![index];
                return ListTile(
                  leading: Icon(
                    _getIconForType(suggestion.type),
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(suggestion.title),
                  subtitle: suggestion.subtitle != null 
                      ? Text(suggestion.subtitle!) 
                      : null,
                  onTap: () {
                    _controller.text = suggestion.title;
                    _focusNode.unfocus();
                    setState(() {
                      _showSuggestions = false;
                    });
                    widget.onSuggestionTapped?.call(suggestion);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getIconForType(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.business:
        return Icons.business;
      case SearchSuggestionType.event:
        return Icons.event;
      case SearchSuggestionType.service:
        return Icons.account_balance;
      case SearchSuggestionType.location:
        return Icons.place;
    }
  }
}

class SearchSuggestion {
  final String title;
  final String? subtitle;
  final SearchSuggestionType type;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? data;

  SearchSuggestion({
    required this.title,
    this.subtitle,
    required this.type,
    this.latitude,
    this.longitude,
    this.data,
  });
}

enum SearchSuggestionType {
  business,
  event,
  service,
  location,
}