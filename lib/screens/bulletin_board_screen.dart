// lib/screens/bulletin_board_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/index.dart' hide BulletinBoardProvider;
import '../models/post.dart';
import '../models/post_item.dart';
import '../providers/bulletin_board_provider.dart';

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BulletinBoardProvider>().loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BulletinBoardProvider>(
      builder: (context, provider, child) {
        return ScaffoldWrapper(
          appBar: AppBar(
            title: const Text('Community Board'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterDialog(provider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  provider.loadPosts();
                  CustomSnackBar.showInfo(context, 'Refreshing posts...');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCategoryChips(provider),
              Expanded(child: _buildPostsList(provider)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showCreatePostForm();
            },
            tooltip: 'Create new post',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips(BulletinBoardProvider provider) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: provider.selectedCategory == null,
            onSelected: (selected) {
              if (selected) {
                provider.setSelectedCategory(null);
              }
            },
          ),
          const SizedBox(width: 8),
          ...provider.categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: provider.selectedCategory == category,
                onSelected: (selected) {
                  provider.setSelectedCategory(selected ? category : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPostsList(BulletinBoardProvider provider) {
    final posts =
        _getMockPosts()
            .map(
              (post) => PostItem(
                id: post.id,
                title: post.title,
                description: post.description,
                category: post.category,
                authorName: post.authorName,
                createdAt: post.createdAt,
                imageUrls: post.imageUrls,
              ),
            )
            .toList();

    return CustomListView<PostItem>(
      items: posts,
      itemBuilder:
          (context, post, index) => PostCard(
            title: post.title,
            description: post.description,
            category: post.category,
            authorName: post.authorName,
            createdAt: post.createdAt,
            imageUrls: post.imageUrls,
            isOwner: index % 3 == 0, // Mock ownership
            onTap: () {
              CustomSnackBar.showInfo(context, 'Opening ${post.title}...');
            },
            onEdit: () {
              CustomSnackBar.showInfo(context, 'Edit feature coming soon!');
            },
            onDelete: () {
              provider.deletePost(post.id);
              CustomSnackBar.showSuccess(context, 'Post deleted successfully');
            },
            onReport: () {
              CustomSnackBar.showWarning(context, 'Post reported for review');
            },
          ),
      isLoading: provider.isLoading,
      onRefresh: () => provider.loadPosts(),
    );
  }

  void _showCreatePostForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostForm(
              onSubmit: (formData) {
                // Create new post
                final newPost = PostItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: formData.title,
                  description: formData.description,
                  category: formData.category,
                  authorName: 'Current User', // Replace with actual user
                  createdAt: DateTime.now(),
                );

                context.read<BulletinBoardProvider>().createPost(newPost);
                Navigator.pop(context);
                CustomSnackBar.showSuccess(
                  context,
                  'Post created successfully!',
                );
              },
            ),
      ),
    );
  }

  void _showFilterDialog(BulletinBoardProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Posts'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select category:'),
                const SizedBox(height: 16),
                ...provider.categories.map(
                  (category) => RadioListTile<String?>(
                    title: Text(category),
                    value: category,
                    groupValue: provider.selectedCategory,
                    onChanged: (value) {
                      provider.setSelectedCategory(value);
                      Navigator.pop(context);
                    },
                  ),
                ),
                RadioListTile<String?>(
                  title: const Text('All Categories'),
                  value: null,
                  groupValue: provider.selectedCategory,
                  onChanged: (value) {
                    provider.setSelectedCategory(null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  List<Post> _getMockPosts() {
    return [
      Post(
        id: '1',
        title: 'iPhone 12 for Sale',
        description:
            'Excellent condition iPhone 12, 128GB, unlocked. Includes original box and charger.',
        type: PostType.buySell,
        category: 'Buy/Sell',
        authorName: 'Sarah Johnson',
        authorContact: 'sarah.j@email.com',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        price: 450.00,
        location: 'Downtown Area',
        viewCount: 23,
        tags: ['electronics', 'phone', 'apple'],
      ),
      Post(
        id: '2',
        title: 'Part-time Barista Wanted',
        description:
            'Local coffee shop seeking friendly barista for weekend shifts. Experience preferred but will train.',
        type: PostType.job,
        category: 'Jobs',
        authorName: 'Mike\'s Coffee Shop',
        authorContact: '(555) 123-4567',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        location: 'Main Street',
        viewCount: 45,
        tags: ['part-time', 'coffee', 'customer-service'],
      ),
      Post(
        id: '3',
        title: 'Lost Cat - Fluffy',
        description:
            'Orange tabby cat, very friendly. Last seen near Central Park. Please call if found!',
        type: PostType.lostFound,
        category: 'Lost & Found',
        authorName: 'Emma Wilson',
        authorContact: '(555) 987-6543',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        location: 'Central Park Area',
        viewCount: 67,
        tags: ['cat', 'orange', 'friendly'],
      ),
      Post(
        id: '4',
        title: 'Volunteers Needed for Beach Cleanup',
        description:
            'Join us this Saturday for our monthly beach cleanup event. Supplies provided, just bring yourself!',
        type: PostType.volunteer,
        category: 'Volunteer',
        authorName: 'Green Earth Society',
        authorContact: 'volunteer@greenearth.org',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        location: 'Sunset Beach',
        viewCount: 89,
        tags: ['environment', 'cleanup', 'community'],
      ),
    ];
  }
}
