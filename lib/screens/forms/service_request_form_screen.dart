// lib/screens/forms/service_request_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request.dart';
import '../../services/form_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/index.dart';

class ServiceRequestFormScreen extends StatefulWidget {
  final ServiceRequest? existingRequest; // For editing
  
  const ServiceRequestFormScreen({super.key, this.existingRequest});

  @override
  State<ServiceRequestFormScreen> createState() => _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form state
  String _selectedCategory = 'Maintenance';
  ServiceRequestPriority _selectedPriority = ServiceRequestPriority.medium;
  DateTime? _preferredDate;
  List<File> _selectedImages = [];
  List<String> _tags = [];
  bool _isUrgent = false;
  bool _isLoading = false;
  bool _isDraftSaved = false;
  
  // Services
  final FormService _formService = FormService();
  
  // Service request categories
  final List<String> _categories = [
    'Maintenance',
    'Safety',
    'Utilities',
    'Transportation',
    'Environment',
    'Community',
    'Infrastructure',
    'Public Health',
    'Noise Complaint',
    'Other',
  ];

  // Category icons
  final Map<String, IconData> _categoryIcons = {
    'Maintenance': Icons.build,
    'Safety': Icons.security,
    'Utilities': Icons.electrical_services,
    'Transportation': Icons.directions_car,
    'Environment': Icons.eco,
    'Community': Icons.people,
    'Infrastructure': Icons.foundation,
    'Public Health': Icons.health_and_safety,
    'Noise Complaint': Icons.volume_off,
    'Other': Icons.help_outline,
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
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRequest != null ? 'Edit Service Request' : 'New Service Request'),
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
            onPressed: _isLoading ? null : _submitRequest,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'SUBMIT',
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
              // Category selection
              _buildCategorySelector(),
              
              const SizedBox(height: 16),
              
              // Priority selection
              _buildPrioritySelector(),
              
              const SizedBox(height: 16),
              
              // Title field
              _buildTitleField(),
              
              const SizedBox(height: 16),
              
              // Description field
              _buildDescriptionEditor(),
              
              const SizedBox(height: 16),
              
              // Image picker
              _buildImagePicker(),
              
              const SizedBox(height: 16),
              
              // Location fields
              _buildLocationFields(),
              
              const SizedBox(height: 16),
              
              // Contact information
              _buildContactInfo(),
              
              const SizedBox(height: 16),
              
              // Preferred date
              _buildPreferredDate(),
              
              const SizedBox(height: 16),
              
              // Urgent checkbox
              _buildUrgentCheckbox(),
              
              const SizedBox(height: 16),
              
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

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                  _markDraftUnsaved();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt())
                        : Colors.grey[50],
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _categoryIcons[category] ?? Icons.help_outline,
                        size: 20,
                        color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected 
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: ServiceRequestPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            Color priorityColor;
            
            switch (priority) {
              case ServiceRequestPriority.low:
                priorityColor = Colors.green;
                break;
              case ServiceRequestPriority.medium:
                priorityColor = Colors.orange;
                break;
              case ServiceRequestPriority.high:
                priorityColor = Colors.red;
                break;
              case ServiceRequestPriority.urgent:
                priorityColor = Colors.red[800]!;
                break;
            }
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                  _markDraftUnsaved();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? priorityColor.withAlpha((0.1 * 255).toInt()) : Colors.grey[50],
                    border: Border.all(
                      color: isSelected ? priorityColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        priority == ServiceRequestPriority.urgent
                            ? Icons.priority_high
                            : Icons.flag,
                        color: isSelected ? priorityColor : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? priorityColor : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Issue Title',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Briefly describe the issue...',
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

  Widget _buildDescriptionEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Description',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Provide detailed information about the issue, including when it started, how it affects you, and any relevant details...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 10,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
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
              'Photos (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photos'),
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
                  Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Add photos to help illustrate the issue',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'General location (e.g., Main Street, Community Park)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
              tooltip: 'Use current location',
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please specify the location';
            }
            return null;
          },
          onChanged: (_) => _markDraftUnsaved(),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: 'Specific address (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
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
          'Contact Information (Optional)',
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
                  hintText: 'Phone number',
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
                  hintText: 'Email address',
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

  Widget _buildPreferredDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Resolution Date (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectPreferredDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  _preferredDate != null
                      ? '${_preferredDate!.month}/${_preferredDate!.day}/${_preferredDate!.year}'
                      : 'Select preferred date',
                  style: TextStyle(
                    color: _preferredDate != null ? Colors.black : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_preferredDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _preferredDate = null;
                      });
                      _markDraftUnsaved();
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isUrgent,
          onChanged: (value) {
            setState(() {
              _isUrgent = value ?? false;
            });
            _markDraftUnsaved();
          },
        ),
        const Expanded(
          child: Text(
            'This is an urgent issue requiring immediate attention',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: 'Enter tags separated by commas...',
            border: OutlineInputBorder(),
            helperText: 'e.g., recurring, safety hazard, affects multiple units',
          ),
          onChanged: (value) {
            _tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
            _markDraftUnsaved();
          },
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags.map((tag) {
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
        onPressed: _isLoading ? null : _submitRequest,
        child: _isLoading
            ? const CircularProgressIndicator()
            : Text(
                widget.existingRequest != null ? 'UPDATE REQUEST' : 'SUBMIT REQUEST',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Helper methods

  void _markDraftUnsaved() {
    if (_isDraftSaved) {
      setState(() {
        _isDraftSaved = false;
      });
    }
  }

  Future<void> _loadDraftOrExisting() async {
    if (widget.existingRequest != null) {
      _loadExistingRequest();
    } else {
      final draft = await _formService.loadServiceRequestDraft();
      if (draft != null) {
        _loadDraft(draft);
      }
    }
  }

  void _loadExistingRequest() {
    final request = widget.existingRequest!;
    _titleController.text = request.title;
    _selectedCategory = request.category;
    _selectedPriority = request.priority;
    _locationController.text = request.location ?? '';
    _addressController.text = request.address ?? '';
    _phoneController.text = request.contactInfo?['phone'] ?? '';
    _emailController.text = request.contactInfo?['email'] ?? '';
    _preferredDate = request.preferredDate;
    _isUrgent = request.isUrgent;
    _tags = List.from(request.tags);
    _tagsController.text = _tags.join(', ');
    
    _descriptionController.text = request.description;
  }

  void _loadDraft(ServiceRequestDraft draft) {
    _titleController.text = draft.title;
    _selectedCategory = draft.category;
    _selectedPriority = draft.priority;
    _selectedImages = List.from(draft.imageFiles);
    _locationController.text = draft.location ?? '';
    _addressController.text = draft.address ?? '';
    _phoneController.text = draft.contactInfo?['phone'] ?? '';
    _emailController.text = draft.contactInfo?['email'] ?? '';
    _preferredDate = draft.preferredDate;
    _isUrgent = draft.isUrgent;
    _tags = List.from(draft.tags);
    _tagsController.text = _tags.join(', ');
    
    _descriptionController.text = draft.description;
    
    setState(() {
      _isDraftSaved = true;
    });
  }

  Future<void> _saveDraft() async {
    final draft = ServiceRequestDraft(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      priority: _selectedPriority,
      location: _locationController.text.isEmpty ? null : _locationController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      contactInfo: _getContactInfo(),
      imageFiles: _selectedImages,
      preferredDate: _preferredDate,
      tags: _tags,
      isUrgent: _isUrgent,
      savedAt: DateTime.now(),
    );

    await _formService.saveServiceRequestDraft(draft);
    if (!mounted) return;
    setState(() {
      _isDraftSaved = true;
    });
    CustomSnackBar.showSuccess(context, 'Draft saved');
  }

  Future<void> _pickImages() async {
    try {
      final images = await _formService.pickMultipleImages(maxImages: 5);
      if (!mounted) return;
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
      if (!mounted) return;
      CustomSnackBar.showError(context, 'Failed to pick images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _markDraftUnsaved();
  }

  Future<void> _getCurrentLocation() async {
    CustomSnackBar.showInfo(context, 'GPS location picker coming soon!');
  }

  Future<void> _selectPreferredDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (date != null) {
      setState(() {
        _preferredDate = date;
      });
      _markDraftUnsaved();
    }
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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isSignedIn) {
      CustomSnackBar.showError(context, 'Please sign in to submit a service request');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final description = _descriptionController.text;
      if (description.trim().isEmpty) {
        CustomSnackBar.showError(context, 'Please provide a detailed description');
        return;
      }
      final draft = ServiceRequestDraft(
        title: _titleController.text.trim(),
        description: description,
        category: _selectedCategory,
        priority: _selectedPriority,
        location: _locationController.text.isEmpty ? null : _locationController.text.trim(),
        address: _addressController.text.isEmpty ? null : _addressController.text.trim(),
        contactInfo: _getContactInfo(),
        imageFiles: _selectedImages,
        preferredDate: _preferredDate,
        tags: _tags,
        isUrgent: _isUrgent,
        savedAt: DateTime.now(),
      );
      final serviceRequest = await _formService.submitServiceRequest(draft);
      if (!mounted) return;
      CustomSnackBar.showSuccess(context, 'Service request submitted successfully!');
      Navigator.pop(context, serviceRequest);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, 'Failed to submit service request: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
}