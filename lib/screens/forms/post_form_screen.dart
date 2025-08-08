// lib/screens/forms/post_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/form_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/index.dart';

class PostFormScreen extends StatefulWidget {
  final Post? existingPost; // For editing

  const PostFormScreen({super.key, this.existingPost});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _tagsController = TextEditingController();

  // Content editor
  final _contentController = TextEditingController();

  // Form state
  PostType _selectedType = PostType.general;
  String _selectedCategory = 'General';
  List<File> _selectedImages = [];
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isDraftSaved = false;

  // Services
  final FormService _formService = FormService();

  // Categories by post type
  final Map<PostType, List<String>> _categoriesByType = {
    PostType.general: ['General', 'Announcements', 'Questions', 'Discussion'],
    PostType.buySell: [
      'Electronics',
      'Furniture',
      'Clothing',
      'Books',
      'Vehicles',
      'Other',
    ],
    PostType.job: [
      'Full-time',
      'Part-time',
      'Contract',
      'Internship',
      'Volunteer',
    ],
    PostType.housing: ['For Rent', 'For Sale', 'Roommate', 'Sublet'],
    PostType.lostFound: ['Lost', 'Found'],
    PostType.service: ['Offered', 'Needed'],
  };

  @override
  void initState() {
    super.initState();
    _loadDraftOrExisting();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _tagsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPost != null ? 'Edit Post' : 'Create Post'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Save draft button
          IconButton(
            icon: Icon(_isDraftSaved ? Icons.cloud_done : Icons.save),
            onPressed: _saveDraft,
            tooltip: 'Save Draft',
          ),
          // Submit button
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(
                      'POST',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post type selection
              _buildPostTypeSelector(),

              const SizedBox(height: 16),

              // Category selection
              _buildCategorySelector(),

              const SizedBox(height: 16),

              // Title field
              _buildTitleField(),

              const SizedBox(height: 16),

              // Rich text content editor
              _buildContentEditor(),

              const SizedBox(height: 16),

              // Image picker
              _buildImagePicker(),

              const SizedBox(height: 16),

              // Location picker
              _buildLocationPicker(),

              const SizedBox(height: 16),

              // Price field (for buy/sell posts)
              if (_selectedType == PostType.buySell) ...[
                _buildPriceField(),
                const SizedBox(height: 16),
              ],

              // Contact info (for relevant post types)
              if (_needsContactInfo()) ...[
                _buildContactInfo(),
                const SizedBox(height: 16),
              ],

              // Tags
              _buildTagsField(),

              const SizedBox(height: 32),

              // Submit button
              _buildSubmitButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Post Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              PostType.values.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type;
                      _selectedCategory = _categoriesByType[type]!.first;
                    });
                  },
                  selectedColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = _categoriesByType[_selectedType] ?? ['General'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items:
              categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Enter a descriptive title...',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 5) {
              return 'Title must be at least 5 characters';
            }
            return null;
          },
          onChanged: (_) => _markDraftUnsaved(),
        ),
      ],
    );
  }

  Widget _buildContentEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'Write your post content here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 10,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter some content';
              }
              return null;
            },
            onChanged: (_) => _markDraftUnsaved(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No images selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Enter location or address...',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map),
              onPressed: _pickLocationFromMap,
              tooltip: 'Pick from map',
            ),
          ),
          onChanged: (_) => _markDraftUnsaved(),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter price...',
            border: OutlineInputBorder(),
            prefixText: '\$ ',
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final price = double.tryParse(value);
              if (price == null || price < 0) {
                return 'Please enter a valid price';
              }
            }
            return null;
          },
          onChanged: (_) => _markDraftUnsaved(),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                onChanged: (_) => _markDraftUnsaved(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                onChanged: (_) => _markDraftUnsaved(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: 'Enter tags separated by commas...',
            border: OutlineInputBorder(),
            helperText: 'e.g., urgent, negotiable, pickup only',
          ),
          onChanged: (value) {
            _tags =
                value
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
            _markDraftUnsaved();
          },
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                        _tagsController.text = _tags.join(', ');
                      });
                      _markDraftUnsaved();
                    },
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPost,
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                  widget.existingPost != null ? 'UPDATE POST' : 'PUBLISH POST',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  // Helper methods

  bool _needsContactInfo() {
    return [
      PostType.buySell,
      PostType.job,
      PostType.housing,
      PostType.service,
    ].contains(_selectedType);
  }

  void _markDraftUnsaved() {
    if (_isDraftSaved) {
      setState(() {
        _isDraftSaved = false;
      });
    }
  }

  Future<void> _loadDraftOrExisting() async {
    if (widget.existingPost != null) {
      // Load existing post for editing
      _loadExistingPost();
    } else {
      // Try to load draft
      final draft = await _formService.loadPostDraft();
      if (draft != null) {
        _loadDraft(draft);
      }
    }
  }

  void _loadExistingPost() {
    final post = widget.existingPost!;
    _titleController.text = post.title;
    _selectedType = post.type;
    _selectedCategory = post.category;
    _locationController.text = post.location ?? '';
    _priceController.text = post.price?.toString() ?? '';
    _phoneController.text = post.authorContact ?? '';
    _tags = List.from(post.tags);
    _tagsController.text = _tags.join(', ');

    // Load content
    _contentController.text = post.description;
  }

  void _loadDraft(PostDraft draft) {
    _titleController.text = draft.title;
    _selectedType = draft.type;
    _selectedCategory = draft.category;
    _selectedImages = List.from(draft.imageFiles);
    _locationController.text = draft.location ?? '';
    _priceController.text = draft.price?.toString() ?? '';
    _phoneController.text = draft.contactInfo?['phone'] ?? '';
    _emailController.text = draft.contactInfo?['email'] ?? '';
    _tags = List.from(draft.tags);
    _tagsController.text = _tags.join(', ');

    // Load content
    _contentController.text = draft.content;

    setState(() {
      _isDraftSaved = true;
    });
  }

  Future<void> _saveDraft() async {
    final content = _contentController.text;

    final draft = PostDraft(
      title: _titleController.text,
      content: content,
      type: _selectedType,
      category: _selectedCategory,
      imageFiles: _selectedImages,
      location:
          _locationController.text.isEmpty ? null : _locationController.text,
      price:
          _priceController.text.isEmpty
              ? null
              : double.tryParse(_priceController.text),
      contactInfo: _getContactInfo(),
      tags: _tags,
      savedAt: DateTime.now(),
    );

    await _formService.savePostDraft(draft);

    if (!mounted) return;

    setState(() {
      _isDraftSaved = true;
    });

    CustomSnackBar.showSuccess(context, 'Draft saved');
  }

  Future<void> _pickImages() async {
    try {
      final images = await _formService.pickMultipleImages(maxImages: 5);

      // Validate images
      for (final image in images) {
        if (!_formService.isValidImage(image)) {
          CustomSnackBar.showError(context, 'Invalid image format');
          return;
        }
        if (!_formService.isValidImageSize(image)) {
          CustomSnackBar.showError(context, 'Image too large (max 10MB)');
          return;
        }
      }

      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.take(5).toList();
        }
      });

      _markDraftUnsaved();
    } catch (e) {
      CustomSnackBar.showError(context, 'Failed to pick images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _markDraftUnsaved();
  }

  Future<void> _pickLocationFromMap() async {
    // Navigate to map screen for location picking
    // This is a simplified implementation
    CustomSnackBar.showInfo(context, 'Map location picker coming soon!');
  }

  Map<String, String>? _getContactInfo() {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (phone.isEmpty && email.isEmpty) return null;

    return {
      if (phone.isNotEmpty) 'phone': phone,
      if (email.isNotEmpty) 'email': email,
    };
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isSignedIn) {
      CustomSnackBar.showError(context, 'Please sign in to create a post');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final content = _contentController.text;

      if (content.trim().isEmpty) {
        CustomSnackBar.showError(context, 'Please enter some content');
        return;
      }

      final draft = PostDraft(
        title: _titleController.text.trim(),
        content: content,
        type: _selectedType,
        category: _selectedCategory,
        imageFiles: _selectedImages,
        location:
            _locationController.text.isEmpty
                ? null
                : _locationController.text.trim(),
        price:
            _priceController.text.isEmpty
                ? null
                : double.tryParse(_priceController.text),
        contactInfo: _getContactInfo(),
        tags: _tags,
        savedAt: DateTime.now(),
      );

      final post = await _formService.submitPost(draft);

      if (!mounted) return;

      CustomSnackBar.showSuccess(context, 'Post published successfully!');
      Navigator.pop(context, post);
    } catch (e) {
      CustomSnackBar.showError(context, 'Failed to publish post: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
