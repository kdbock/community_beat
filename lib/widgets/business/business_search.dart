import 'package:flutter/material.dart';

/// Search widget for business directory
class BusinessSearch extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onCategoryChanged;
  final List<String> categories;
  final String? selectedCategory;

  const BusinessSearch({
    super.key,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.categories,
    this.selectedCategory,
  });

  @override
  State<BusinessSearch> createState() => _BusinessSearchState();
}

class _BusinessSearchState extends State<BusinessSearch> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search businesses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: 12),
          // Category filter
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text('Category:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  hint: const Text('All Categories'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...widget.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }),
                  ],
                  onChanged: widget.onCategoryChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filter chips for quick category selection
class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (selected) {
              if (selected) {
                onCategorySelected(null);
              }
            },
          ),
          const SizedBox(width: 8),
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (selected) {
                  onCategorySelected(selected ? category : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}