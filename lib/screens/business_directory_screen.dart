// lib/screens/business_directory_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/index.dart';
import '../models/business.dart';
import '../models/business_item.dart' as models;
import '../utils/constants.dart';
import '../providers/business_directory_provider.dart';

class BusinessDirectoryScreen extends StatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  State<BusinessDirectoryScreen> createState() =>
      _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends State<BusinessDirectoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessDirectoryProvider>().loadBusinesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessDirectoryProvider>(
      builder: (context, provider, child) {
        return ScaffoldWrapper(
          appBar: AppBar(
            title: const Text('Business Directory'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: () {
                  CustomSnackBar.showInfo(context, 'Map view coming soon!');
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  provider.loadBusinesses();
                  CustomSnackBar.showInfo(context, 'Refreshing businesses...');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              BusinessSearch(
                onSearchChanged: (query) => provider.setSearchQuery(query),
                onCategoryChanged:
                    (category) => provider.setSelectedCategory(category),
                categories: _getCategories(),
                selectedCategory: provider.selectedCategory,
              ),
              Expanded(child: _buildBusinessList(provider)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              CustomSnackBar.showInfo(
                context,
                'Add business feature coming soon!',
              );
            },
            tooltip: 'Add business',
            child: const Icon(Icons.add_business),
          ),
        );
      },
    );
  }

  Widget _buildBusinessList(BusinessDirectoryProvider provider) {
    final businesses =
        _getMockBusinesses()
            .map(
              (business) => models.BusinessItem(
                id: business.id,
                name: business.name,
                description: business.description,
                imageUrl: business.imageUrl,
                phone: business.phone,
                email: business.email,
                category: business.category,
                rating: business.rating,
                hasDeals: business.deals.isNotEmpty,
                isNew: business.isNew,
                onTap: () {
                  CustomSnackBar.showInfo(
                    context,
                    'Opening ${business.name}...',
                  );
                },
              ),
            )
            .toList();

    return BusinessList<models.BusinessItem>(
      businesses: businesses,
      isLoading: provider.isLoading,
      onRefresh: () => provider.loadBusinesses(),
    );
  }

  List<String> _getCategories() {
    return AppConstants.businessCategories
        .where((cat) => cat != 'All')
        .toList();
  }

  List<Business> _getMockBusinesses() {
    return [
      Business(
        id: '1',
        name: 'Joe\'s Pizza',
        description:
            'Authentic Italian pizza made with fresh ingredients. Family owned since 1985.',
        category: 'Restaurants',
        address: '123 Main Street, Downtown',
        phone: '(555) 123-4567',
        email: 'info@joespizza.com',
        website: 'https://joespizza.com',
        hours: {
          'Monday': '11:00 AM - 10:00 PM',
          'Tuesday': '11:00 AM - 10:00 PM',
          'Wednesday': '11:00 AM - 10:00 PM',
          'Thursday': '11:00 AM - 10:00 PM',
          'Friday': '11:00 AM - 11:00 PM',
          'Saturday': '11:00 AM - 11:00 PM',
          'Sunday': '12:00 PM - 9:00 PM',
        },
        rating: 4.5,
        reviewCount: 127,
        isVerified: true,
        deals: [
          Deal(
            id: '1',
            title: '20% Off Large Pizzas',
            description: 'Get 20% off any large pizza on weekdays',
            discountPercentage: '20%',
            expiryDate: DateTime.now().add(const Duration(days: 30)),
          ),
        ],
      ),
      Business(
        id: '2',
        name: 'Smith Auto Repair',
        description:
            'Professional auto repair services with certified mechanics. All makes and models.',
        category: 'Automotive',
        address: '456 Oak Avenue, Industrial District',
        phone: '(555) 987-6543',
        email: 'service@smithauto.com',
        hours: {
          'Monday': '8:00 AM - 6:00 PM',
          'Tuesday': '8:00 AM - 6:00 PM',
          'Wednesday': '8:00 AM - 6:00 PM',
          'Thursday': '8:00 AM - 6:00 PM',
          'Friday': '8:00 AM - 6:00 PM',
          'Saturday': '9:00 AM - 4:00 PM',
          'Sunday': 'Closed',
        },
        rating: 4.8,
        reviewCount: 89,
        isVerified: true,
        services: [
          'Oil Change',
          'Brake Repair',
          'Engine Diagnostics',
          'Tire Service',
        ],
      ),
      Business(
        id: '3',
        name: 'Green Thumb Garden Center',
        description:
            'Your local source for plants, gardening supplies, and landscaping advice.',
        category: 'Shopping',
        address: '789 Garden Lane, Suburbs',
        phone: '(555) 456-7890',
        website: 'https://greenthumbgarden.com',
        hours: {
          'Monday': '9:00 AM - 7:00 PM',
          'Tuesday': '9:00 AM - 7:00 PM',
          'Wednesday': '9:00 AM - 7:00 PM',
          'Thursday': '9:00 AM - 7:00 PM',
          'Friday': '9:00 AM - 7:00 PM',
          'Saturday': '8:00 AM - 8:00 PM',
          'Sunday': '10:00 AM - 6:00 PM',
        },
        rating: 4.2,
        reviewCount: 45,
        isVerified: false,
      ),
    ];
  }
}
