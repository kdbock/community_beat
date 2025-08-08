import 'package:flutter/material.dart';
import 'business_card.dart';
import '../../models/business_item.dart';

/// Grid view for displaying business cards
class BusinessGrid extends StatelessWidget {
  final List<BusinessItem> businesses;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final ScrollController? scrollController;

  const BusinessGrid({
    super.key,
    required this.businesses,
    this.isLoading = false,
    this.onRefresh,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && businesses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No businesses found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    Widget gridView = GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: businesses.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == businesses.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final business = businesses[index];
        return BusinessCard(
          name: business.name,
          description: business.description,
          imageUrl: business.imageUrl,
          phone: business.phone,
          email: business.email,
          website: business.website,
          category: business.category,
          rating: business.rating,
          hasDeals: business.hasDeals,
          isNew: business.isNew,
          onTap: () => business.onTap?.call(),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          onRefresh!();
        },
        child: gridView,
      );
    }

    return gridView;
  }
}

/// Alternative list view for businesses
class BusinessList<T extends BusinessItem> extends StatelessWidget {
  final List<T> businesses;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final ScrollController? scrollController;

  const BusinessList({
    super.key,
    required this.businesses,
    this.isLoading = false,
    this.onRefresh,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && businesses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No businesses found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    Widget listView = ListView.builder(
      controller: scrollController,
      itemCount: businesses.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == businesses.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final business = businesses[index];
        return BusinessCard(
          name: business.name,
          description: business.description,
          imageUrl: business.imageUrl,
          phone: business.phone,
          email: business.email,
          website: business.website,
          category: business.category,
          rating: business.rating,
          hasDeals: business.hasDeals,
          isNew: business.isNew,
          onTap: () => business.onTap?.call(),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          onRefresh!();
        },
        child: listView,
      );
    }

    return listView;
  }
}
