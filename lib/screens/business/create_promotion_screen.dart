// lib/screens/business/create_promotion_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/business_promotion.dart';
import '../../services/business_promotion_service.dart';
import '../../widgets/index.dart';

class CreatePromotionScreen extends StatefulWidget {
  final String businessId;
  final BusinessPromotion? existingPromotion;

  const CreatePromotionScreen({
    super.key,
    required this.businessId,
    this.existingPromotion,
  });

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _freeItemController = TextEditingController();
  final _minimumPurchaseController = TextEditingController();
  final _maxUsesController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _applicableItemsController = TextEditingController();

  PromotionType _selectedType = PromotionType.percentage;
  PromotionStatus _selectedStatus = PromotionStatus.draft;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _requiresCode = false;
  List<String> _selectedTags = [];
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Food & Dining',
    'Shopping',
    'Services',
    'Entertainment',
    'Health & Beauty',
    'Automotive',
    'Home & Garden',
    'Technology',
    'Fashion',
    'Sports & Fitness',
    'Travel',
    'Education',
    'Limited Time',
    'New Customer',
    'Loyalty Reward',
    'Seasonal',
    'Weekend Special',
    'Happy Hour',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPromotion != null) {
      _populateFields(widget.existingPromotion!);
    }
  }

  void _populateFields(BusinessPromotion promotion) {
    _titleController.text = promotion.title;
    _descriptionController.text = promotion.description;
    _selectedType = promotion.type;
    _selectedStatus = promotion.status;
    _startDate = promotion.startDate;
    _endDate = promotion.endDate;
    _requiresCode = promotion.requiresCode;
    _selectedTags = List.from(promotion.tags);

    if (promotion.discountPercentage != null) {
      _discountPercentageController.text = promotion.discountPercentage.toString();
    }
    if (promotion.discountAmount != null) {
      _discountAmountController.text = promotion.discountAmount.toString();
    }
    if (promotion.freeItem != null) {
      _freeItemController.text = promotion.freeItem!;
    }
    if (promotion.minimumPurchase != null) {
      _minimumPurchaseController.text = promotion.minimumPurchase.toString();
    }
    if (promotion.maxUses != null) {
      _maxUsesController.text = promotion.maxUses.toString();
    }
    if (promotion.promoCode != null) {
      _promoCodeController.text = promotion.promoCode!;
    }
    if (promotion.applicableItems.isNotEmpty) {
      _applicableItemsController.text = promotion.applicableItems.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _discountAmountController.dispose();
    _freeItemController.dispose();
    _minimumPurchaseController.dispose();
    _maxUsesController.dispose();
    _promoCodeController.dispose();
    _applicableItemsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
        if (_selectedImages.length > 3) {
          _selectedImages = _selectedImages.take(3).toList();
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _generatePromoCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[random % chars.length]).join();
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Upload images to Firebase Storage and get URLs
      final List<String> imageUrls = []; // For now, empty list

      final promotion = BusinessPromotion(
        id: widget.existingPromotion?.id ?? '',
        businessId: widget.businessId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        status: _selectedStatus,
        discountPercentage: _selectedType == PromotionType.percentage 
            ? double.tryParse(_discountPercentageController.text) 
            : null,
        discountAmount: _selectedType == PromotionType.fixedAmount 
            ? double.tryParse(_discountAmountController.text) 
            : null,
        freeItem: _selectedType == PromotionType.freeItem 
            ? _freeItemController.text.trim().isNotEmpty 
                ? _freeItemController.text.trim() 
                : null 
            : null,
        applicableItems: _applicableItemsController.text.trim().isNotEmpty
            ? _applicableItemsController.text.split(',').map((e) => e.trim()).toList()
            : [],
        minimumPurchase: _minimumPurchaseController.text.trim().isNotEmpty
            ? double.tryParse(_minimumPurchaseController.text)
            : null,
        maxUses: _maxUsesController.text.trim().isNotEmpty
            ? int.tryParse(_maxUsesController.text)
            : null,
        currentUses: widget.existingPromotion?.currentUses ?? 0,
        startDate: _startDate,
        endDate: _endDate,
        imageUrls: imageUrls,
        promoCode: _requiresCode ? _promoCodeController.text.trim() : null,
        requiresCode: _requiresCode,
        tags: _selectedTags,
        createdAt: widget.existingPromotion?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingPromotion != null) {
        await BusinessPromotionService.updatePromotion(widget.existingPromotion!.id, promotion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promotion updated successfully!')),
          );
        }
      } else {
        await BusinessPromotionService.createPromotion(promotion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promotion created successfully!')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: Text(
          widget.existingPromotion != null ? 'Edit Promotion' : 'Create Promotion',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitPromotion,
              child: const Text(
                'Save',
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Promotion Title',
                        hintText: 'e.g., 20% Off All Items',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your promotion...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Promotion Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promotion Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<PromotionType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: PromotionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Type-specific fields
                    if (_selectedType == PromotionType.percentage)
                      TextFormField(
                        controller: _discountPercentageController,
                        decoration: const InputDecoration(
                          labelText: 'Discount Percentage',
                          hintText: 'e.g., 20',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter discount percentage';
                          }
                          final percentage = double.tryParse(value);
                          if (percentage == null || percentage <= 0 || percentage > 100) {
                            return 'Please enter a valid percentage (1-100)';
                          }
                          return null;
                        },
                      ),
                    
                    if (_selectedType == PromotionType.fixedAmount)
                      TextFormField(
                        controller: _discountAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Discount Amount',
                          hintText: 'e.g., 10.00',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter discount amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    
                    if (_selectedType == PromotionType.freeItem)
                      TextFormField(
                        controller: _freeItemController,
                        decoration: const InputDecoration(
                          labelText: 'Free Item',
                          hintText: 'e.g., Free Coffee',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the free item';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Conditions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conditions (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _minimumPurchaseController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Purchase Amount',
                        hintText: 'e.g., 50.00',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _maxUsesController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Uses',
                        hintText: 'Leave empty for unlimited',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _applicableItemsController,
                      decoration: const InputDecoration(
                        labelText: 'Applicable Items',
                        hintText: 'e.g., Pizza, Burgers, Drinks (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Date'),
                            subtitle: Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            ),
                            leading: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, true),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Date'),
                            subtitle: Text(
                              '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                            ),
                            leading: const Icon(Icons.event),
                            onTap: () => _selectDate(context, false),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Promo Code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promo Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    CheckboxListTile(
                      title: const Text('Require promo code'),
                      subtitle: const Text('Customers must enter a code to redeem'),
                      value: _requiresCode,
                      onChanged: (value) {
                        setState(() {
                          _requiresCode = value ?? false;
                          if (_requiresCode && _promoCodeController.text.isEmpty) {
                            _promoCodeController.text = _generatePromoCode();
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    if (_requiresCode) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _promoCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Promo Code',
                                border: OutlineInputBorder(),
                              ),
                              validator: _requiresCode ? (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a promo code';
                                }
                                return null;
                              } : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _promoCodeController.text = _generatePromoCode();
                            },
                            child: const Text('Generate'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tags
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select tags to help customers find your promotion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (_) => _toggleTag(tag),
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Images
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Images (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _selectedImages.length < 3 ? _pickImages : null,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Images'),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
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
                                      width: 100,
                                      height: 100,
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
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Add up to 3 images (${_selectedImages.length}/3)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<PromotionStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: PromotionStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusDisplayName(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPromotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.existingPromotion != null ? 'Update Promotion' : 'Create Promotion',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(PromotionType type) {
    switch (type) {
      case PromotionType.percentage:
        return 'Percentage Discount';
      case PromotionType.fixedAmount:
        return 'Fixed Amount Discount';
      case PromotionType.buyOneGetOne:
        return 'Buy One Get One';
      case PromotionType.freeItem:
        return 'Free Item';
      case PromotionType.bundle:
        return 'Bundle Deal';
      case PromotionType.other:
        return 'Other';
    }
  }

  String _getStatusDisplayName(PromotionStatus status) {
    switch (status) {
      case PromotionStatus.draft:
        return 'Draft';
      case PromotionStatus.active:
        return 'Active';
      case PromotionStatus.paused:
        return 'Paused';
      case PromotionStatus.expired:
        return 'Expired';
      case PromotionStatus.cancelled:
        return 'Cancelled';
    }
  }
}