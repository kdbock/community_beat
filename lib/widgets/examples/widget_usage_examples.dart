import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../index.dart';
import '../../providers/app_state_provider.dart' as app;
import '../../providers/news_events_provider.dart' as news;
import '../../providers/business_directory_provider.dart' as business;
import '../../providers/bulletin_board_provider.dart' as bulletin;
import '../../models/post_item.dart' as models;
import '../../models/business_item.dart' as models;

/// Example showing how to use the global widgets together
class GlobalWidgetsExample extends StatefulWidget {
  const GlobalWidgetsExample({super.key});

  @override
  State<GlobalWidgetsExample> createState() => _GlobalWidgetsExampleState();
}

class _GlobalWidgetsExampleState extends State<GlobalWidgetsExample> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<app.AppStateProvider>(
      builder: (context, appState, child) {
        return ScaffoldWrapper(
          appBar: AppBar(
            title: const Text('Community Beat'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  InAppNotification.show(
                    context,
                    title: 'New Notification',
                    message: 'You have a new message!',
                    icon: Icons.message,
                  );
                },
              ),
            ],
          ),
          drawer: const CustomDrawer(),
          body: _buildBody(),
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              appState.setBottomNavIndex(index);
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              CustomSnackBar.showSuccess(context, 'Action completed!');
            },
            tooltip: 'Add new item',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const NewsEventsExample();
      case 1:
        return const BusinessDirectoryExample();
      case 2:
        return const BulletinBoardExample();
      case 3:
        return const PublicServicesExample();
      case 4:
        return const MapExample();
      default:
        return const Center(child: Text('Page not found'));
    }
  }
}

/// Example of News & Events widgets
class NewsEventsExample extends StatelessWidget {
  const NewsEventsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<news.NewsEventsProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Calendar
            EventCalendar(
              eventDates: provider.getEventDates(),
              onDaySelected: (date) {
                provider.setSelectedDate(date);
              },
              selectedDay: provider.selectedDate,
            ),
            // News List
            Expanded(
              child: NewsList(
                newsItems:
                    provider.newsItems
                        .map(
                          (item) => NewsItem(
                            id: item.id,
                            title: item.title,
                            description: item.description,
                            imageUrl: item.imageUrl,
                            publishedAt: item.publishedAt,
                            isEvent: item.isEvent,
                            eventDate: item.eventDate,
                          ),
                        )
                        .toList(),
                isLoading: provider.isLoading,
                onRefresh: () => provider.loadNews(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Example of Business Directory widgets
class BusinessDirectoryExample extends StatelessWidget {
  const BusinessDirectoryExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<business.BusinessDirectoryProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Search and filters
            BusinessSearch(
              onSearchChanged: (query) => provider.setSearchQuery(query),
              onCategoryChanged:
                  (category) => provider.setSelectedCategory(category),
              categories: provider.categories,
              selectedCategory: provider.selectedCategory,
            ),
            // Business grid
            Expanded(
              child: BusinessGrid(
                businesses:
                    provider.businesses
                        .map(
                          (item) => models.BusinessItem(
                            id: item.id,
                            name: item.name,
                            description: item.description,
                            imageUrl: item.imageUrl,
                            phone: item.phone,
                            email: item.email,
                            category: item.category,
                            rating: item.rating,
                            hasDeals: item.hasDeals,
                            isNew: item.isNew,
                          ),
                        )
                        .toList(),
                isLoading: provider.isLoading,
                onRefresh: () => provider.loadBusinesses(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Example of Bulletin Board widgets
class BulletinBoardExample extends StatelessWidget {
  const BulletinBoardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<bulletin.BulletinBoardProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Category chips
            CategoryChips(
              categories: provider.categories,
              selectedCategory: provider.selectedCategory,
              onCategorySelected:
                  (category) => provider.setSelectedCategory(category),
            ),
            // Posts list
            Expanded(
              child: CustomListView<models.PostItem>(
                items: provider.posts,
                itemBuilder:
                    (context, post, index) => PostCard(
                      id: post.id,
                      title: post.title,
                      description: post.description,
                      category: post.category,
                      authorName: post.authorName,
                      createdAt: post.createdAt,
                      imageUrls: post.imageUrls,
                      onEdit: () {
                        // Navigate to edit form
                      },
                      onDelete: () => provider.deletePost(post.id),
                      isOwner: true, // Check if current user is owner
                    ),
                isLoading: provider.isLoading,
                onRefresh: () => provider.loadPosts(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Example of Public Services widgets
class PublicServicesExample extends StatelessWidget {
  const PublicServicesExample({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      ServiceData(
        title: 'City Hall',
        description: 'General city services and administration',
        icon: Icons.account_balance,
        phone: '+1234567890',
        email: 'info@cityhall.gov',
      ),
      ServiceData(
        title: 'Police Department',
        description: 'Emergency and non-emergency police services',
        icon: Icons.local_police,
        phone: '911',
        email: 'police@city.gov',
      ),
    ];

    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ServiceCard(
          title: service.title,
          description: service.description,
          icon: service.icon,
          phone: service.phone,
          email: service.email,
          isExpanded: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ServiceRequestForm(
                      serviceTitle: service.title,
                      onSubmit: (data) {
                        // Handle form submission
                        Navigator.pop(context);
                        CustomSnackBar.showSuccess(
                          context,
                          'Service request submitted successfully!',
                        );
                      },
                    ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Example of Map widgets
class MapExample extends StatelessWidget {
  const MapExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomMap(
          initialPosition: const LatLng(37.7749, -122.4194), // San Francisco
          markers: {
            // Add sample markers
          },
          onMapTapped: (position) {
            debugPrint('Map tapped at: $position');
          },
        ),
        MapSearchBar(
          onSearch: (query) {
            debugPrint('Searching for: $query');
          },
          onCurrentLocation: () {
            debugPrint('Getting current location');
          },
        ),
        const MapControls(),
        const MapLegend(),
      ],
    );
  }
}

// Helper data classes
class ServiceData {
  final String title;
  final String description;
  final IconData icon;
  final String? phone;
  final String? email;

  ServiceData({
    required this.title,
    required this.description,
    required this.icon,
    this.phone,
    this.email,
  });
}

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
