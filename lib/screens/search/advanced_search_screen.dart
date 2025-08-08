// lib/screens/search/advanced_search_screen.dart

import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../models/event.dart';
import '../../models/business.dart';
import '../../models/service_request.dart';
import '../../services/search_service.dart';
import '../../widgets/index.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const AdvancedSearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  SearchResults? _searchResults;
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  // Filter states
  String? _selectedCategory;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedLocation;
  // ignore: unused_field
  PostType? _selectedPostType;
  // ignore: unused_field
  ServiceRequestStatus? _selectedStatus;
  // ignore: unused_field
  ServiceRequestPriority? _selectedPriority;
  // ignore: unused_field
  bool _verifiedOnly = false;
  // ignore: unused_field
  bool _upcomingOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
    
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await SearchService.getPopularSearchTerms();
      if (mounted) {
        setState(() => _suggestions = suggestions);
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final results = await SearchService.searchAll(
        query: query,
        filters: _buildFilters(),
      );
      
      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Search failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<SearchFilter> _buildFilters() {
    final filters = <SearchFilter>[];
    
    if (_selectedCategory != null) {
      filters.add(SearchFilter(
        field: 'category',
        type: SearchFilterType.equals,
        value: _selectedCategory,
      ));
    }
    
    if (_dateFrom != null) {
      filters.add(SearchFilter(
        field: 'created_at',
        type: SearchFilterType.greaterThanOrEqual,
        value: _dateFrom,
      ));
    }
    
    if (_dateTo != null) {
      filters.add(SearchFilter(
        field: 'created_at',
        type: SearchFilterType.lessThanOrEqual,
        value: _dateTo,
      ));
    }
    
    return filters;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: const Text(
          'Advanced Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'All (${_searchResults?.totalResults ?? 0})',
              icon: const Icon(Icons.search),
            ),
            Tab(
              text: 'Posts (${_searchResults?.posts.length ?? 0})',
              icon: const Icon(Icons.post_add),
            ),
            Tab(
              text: 'Events (${_searchResults?.events.length ?? 0})',
              icon: const Icon(Icons.event),
            ),
            Tab(
              text: 'Businesses (${_searchResults?.businesses.length ?? 0})',
              icon: const Icon(Icons.business),
            ),
            Tab(
              text: 'Services (${_searchResults?.serviceRequests.length ?? 0})',
              icon: const Icon(Icons.build),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFiltersSection(),
          Expanded(
            child: _searchResults == null
                ? _buildInitialState()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts, events, businesses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                'Category',
                _selectedCategory ?? 'Any',
                () => _showCategoryPicker(),
              ),
              _buildFilterChip(
                'Date From',
                _dateFrom != null
                    ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}'
                    : 'Any',
                () => _showDatePicker(true),
              ),
              _buildFilterChip(
                'Date To',
                _dateTo != null
                    ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}'
                    : 'Any',
                () => _showDatePicker(false),
              ),
              _buildFilterChip(
                'Location',
                _selectedLocation ?? 'Any',
                () => _showLocationPicker(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
              const Spacer(),
              Text(
                '${_searchResults?.totalResults ?? 0} results',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(value),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              return InkWell(
                onTap: () {
                  _searchController.text = suggestion;
                  _performSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Search Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Use specific keywords for better results'),
                  SizedBox(height: 4),
                  Text('• Try searching by category or location'),
                  SizedBox(height: 4),
                  Text('• Use filters to narrow down results'),
                  SizedBox(height: 4),
                  Text('• Search works across posts, events, and businesses'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms or filters',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResultsTab(),
        _buildPostsTab(),
        _buildEventsTab(),
        _buildBusinessesTab(),
        _buildServicesTab(),
      ],
    );
  }

  Widget _buildAllResultsTab() {
    final allResults = _searchResults!.allResults;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allResults.length,
      itemBuilder: (context, index) {
        final item = allResults[index];
        
        if (item is Post) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(
              id: item.id,
              title: item.title,
              description: item.description,
              category: item.category,
              authorName: item.authorName,
              createdAt: item.createdAt,
              imageUrls: item.imageUrls,
              onTap: () {
                // Navigate to post detail
              },
            ),
          );
        } else if (item is Event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EventCard(
              event: item,
              onTap: () {
                // Navigate to event detail
              },
            ),
          );
        } else if (item is Business) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BusinessCard(
              name: item.name,
              description: item.description,
              category: item.category,
              imageUrl: item.imageUrl,
              phone: item.phone,
              email: item.email,
              website: item.website,
              rating: item.rating,
              hasDeals: item.deals.isNotEmpty,
              isNew: item.isNew,
              onTap: () {
                // Navigate to business detail
              },
            ),
          );
        } else if (item is ServiceRequest) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ServiceCard(
              title: item.title,
              description: item.description,
              icon: _getServiceIcon(item.category),
              onTap: () {
                // Navigate to service detail
              },
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPostsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.posts.length,
      itemBuilder: (context, index) {
        final post = _searchResults!.posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PostCard(
            id: post.id,
            title: post.title,
            description: post.description,
            category: post.category,
            authorName: post.authorName,
            createdAt: post.createdAt,
            imageUrls: post.imageUrls,
            onTap: () {
              // Navigate to post detail
            },
          ),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.events.length,
      itemBuilder: (context, index) {
        final event = _searchResults!.events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EventCard(
            event: event,
            onTap: () {
              // Navigate to event detail
            },
          ),
        );
      },
    );
  }

  Widget _buildBusinessesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.businesses.length,
      itemBuilder: (context, index) {
        final business = _searchResults!.businesses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BusinessCard(
            name: business.name,
            description: business.description,
            category: business.category,
            imageUrl: business.imageUrl,
            phone: business.phone,
            email: business.email,
            website: business.website,
            rating: business.rating,
            hasDeals: business.deals.isNotEmpty,
            isNew: business.isNew,
            onTap: () {
              // Navigate to business detail
            },
          ),
        );
      },
    );
  }

  Widget _buildServicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.serviceRequests.length,
      itemBuilder: (context, index) {
        final serviceRequest = _searchResults!.serviceRequests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ServiceCard(
            title: serviceRequest.title,
            description: serviceRequest.description,
            icon: _getServiceIcon(serviceRequest.category),
            onTap: () {
              // Navigate to service detail
            },
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    // TODO: Implement category picker
    CustomSnackBar.showInfo(context, 'Category picker coming soon!');
  }

  void _showDatePicker(bool isFromDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (date != null) {
      setState(() {
        if (isFromDate) {
          _dateFrom = date;
        } else {
          _dateTo = date;
        }
      });
    }
  }

  void _showLocationPicker() {
    // TODO: Implement location picker
    CustomSnackBar.showInfo(context, 'Location picker coming soon!');
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _dateFrom = null;
      _dateTo = null;
      _selectedLocation = null;
      _selectedPostType = null;
      _selectedStatus = null;
      _selectedPriority = null;
      _verifiedOnly = false;
      _upcomingOnly = false;
    });
    
    if (_searchController.text.isNotEmpty) {
      _performSearch();
    }
  }

  IconData _getServiceIcon(String category) {
    switch (category.toLowerCase()) {
      case 'police':
        return Icons.local_police;
      case 'fire':
        return Icons.local_fire_department;
      case 'medical':
      case 'health':
        return Icons.local_hospital;
      case 'maintenance':
      case 'repair':
        return Icons.build;
      case 'transport':
      case 'transportation':
        return Icons.directions_bus;
      case 'utilities':
        return Icons.power;
      case 'education':
        return Icons.school;
      case 'finance':
        return Icons.account_balance;
      case 'legal':
        return Icons.gavel;
      case 'environment':
        return Icons.eco;
      default:
        return Icons.public;
    }
  }
}