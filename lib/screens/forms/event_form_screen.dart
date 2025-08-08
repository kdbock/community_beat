import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../services/form_service.dart';
import '../../widgets/global/custom_snackbar.dart';
import '../../widgets/forms/image_picker_grid.dart';
import '../../widgets/forms/tags_input.dart';

class EventFormScreen extends StatefulWidget {
  final Event? existingEvent;

  const EventFormScreen({
    super.key,
    this.existingEvent,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _ticketPriceController = TextEditingController();

  // Rich text editor
  final _descriptionController = TextEditingController();
  
  // Form state
  String _selectedCategory = 'Community';
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  List<File> _selectedImages = [];
  List<String> _tags = [];
  bool _isRecurring = false;
  String? _recurringPattern;
  bool _requiresTickets = false;
  bool _hasMaxAttendees = false;
  
  // UI state
  bool _isLoading = false;
  bool _isDraftSaved = false;

  // Services
  final FormService _formService = FormService();

  // Event categories
  final List<String> _categories = [
    'Community',
    'Arts & Culture',
    'Sports & Recreation',
    'Education',
    'Business & Networking',
    'Fundraising',
    'Health & Wellness',
    'Family & Kids',
    'Social',
    'Government',
    'Religious',
    'Other',
  ];

  // Recurring patterns
  final List<String> _recurringPatterns = [
    'Daily',
    'Weekly',
    'Bi-weekly',
    'Monthly',
    'Yearly',
  ];

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
    _tagsController.dispose();
    _maxAttendeesController.dispose();
    _ticketPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent != null ? 'Edit Event' : 'Create Event'),
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
            onPressed: _isLoading ? null : _submitEvent,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'PUBLISH',
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
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildDateTimeSection(),
            const SizedBox(height: 16),
            _buildLocationSection(),
            const SizedBox(height: 16),
            _buildRecurringSection(),
            const SizedBox(height: 16),
            _buildTicketingSection(),
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 16),
            _buildTagsSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Title *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Enter event title...',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an event title';
            }
            return null;
          },
          onChanged: (_) => _markDraftUnsaved(),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
            _markDraftUnsaved();
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Description *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText: 'Describe your event in detail...',
            border: OutlineInputBorder(),
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an event description';
            }
            return null;
          },
          onChanged: (_) => _markDraftUnsaved(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Start Date & Time
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickStartDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Start Date',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _pickStartTime,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _startTime != null
                            ? _startTime!.format(context)
                            : 'Start Time',
                        style: TextStyle(
                          color: _startTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // End Date & Time
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'End Date (Optional)',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _pickEndTime,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _endTime != null
                            ? _endTime!.format(context)
                            : 'End Time (Optional)',
                        style: TextStyle(
                          color: _endTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: 'Event location (e.g., Community Center)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the event location';
            }
            return null;
          },
          onChanged: (_) => _markDraftUnsaved(),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: 'Full address (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
          onChanged: (_) => _markDraftUnsaved(),
        ),
      ],
    );
  }

  Widget _buildRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value ?? false;
                  if (!_isRecurring) {
                    _recurringPattern = null;
                  }
                });
                _markDraftUnsaved();
              },
            ),
            const Text(
              'Recurring Event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _recurringPattern,
            decoration: const InputDecoration(
              labelText: 'Recurrence Pattern',
              border: OutlineInputBorder(),
            ),
            items: _recurringPatterns.map((pattern) {
              return DropdownMenuItem(
                value: pattern,
                child: Text(pattern),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _recurringPattern = value;
              });
              _markDraftUnsaved();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTicketingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Ticketing toggle
        Row(
          children: [
            Checkbox(
              value: _requiresTickets,
              onChanged: (value) {
                setState(() {
                  _requiresTickets = value ?? false;
                  if (!_requiresTickets) {
                    _ticketPriceController.clear();
                  }
                });
                _markDraftUnsaved();
              },
            ),
            const Text('Requires Tickets/Payment'),
          ],
        ),
        if (_requiresTickets) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _ticketPriceController,
            decoration: const InputDecoration(
              labelText: 'Ticket Price (\$)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _markDraftUnsaved(),
          ),
        ],
        const SizedBox(height: 8),
        // Max attendees toggle
        Row(
          children: [
            Checkbox(
              value: _hasMaxAttendees,
              onChanged: (value) {
                setState(() {
                  _hasMaxAttendees = value ?? false;
                  if (!_hasMaxAttendees) {
                    _maxAttendeesController.clear();
                  }
                });
                _markDraftUnsaved();
              },
            ),
            const Text('Limit Number of Attendees'),
          ],
        ),
        if (_hasMaxAttendees) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _maxAttendeesController,
            decoration: const InputDecoration(
              labelText: 'Maximum Attendees',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _markDraftUnsaved(),
          ),
        ],
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Images',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ImagePickerGrid(
          images: _selectedImages,
          onImagesChanged: (images) {
            setState(() {
              _selectedImages = images;
            });
            _markDraftUnsaved();
          },
          maxImages: 5,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TagsInput(
          controller: _tagsController,
          tags: _tags,
          onTagsChanged: (tags) {
            setState(() {
              _tags = tags;
            });
            _markDraftUnsaved();
          },
          hintText: 'Add tags to help people find your event...',
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitEvent,
        child: _isLoading
            ? const CircularProgressIndicator()
            : Text(
                widget.existingEvent != null ? 'UPDATE EVENT' : 'PUBLISH EVENT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Date/Time picker methods
  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
      _markDraftUnsaved();
    }
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
      _markDraftUnsaved();
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _markDraftUnsaved();
    }
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
      _markDraftUnsaved();
    }
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
    if (widget.existingEvent != null) {
      _loadExistingEvent();
    } else {
      final draft = await _formService.loadEventDraft();
      if (draft != null) {
        _loadDraft(draft);
      }
    }
  }

  void _loadExistingEvent() {
    final event = widget.existingEvent!;
    _titleController.text = event.title;
    _selectedCategory = event.category;
    _locationController.text = event.location;
    _tags = List.from(event.tags);
    _tagsController.text = _tags.join(', ');

    // Load description
    _descriptionController.text = event.description;

    // Set dates/times
    _startDate = event.startDate;
    _endDate = event.endDate;
    // Note: TimeOfDay extraction would need additional logic
  }

  void _loadDraft(EventDraft draft) {
    _titleController.text = draft.title;
    _selectedCategory = draft.category;
    _locationController.text = draft.location;
    _addressController.text = draft.address ?? '';
    _selectedImages = List.from(draft.imageFiles);
    _tags = List.from(draft.tags);
    _tagsController.text = _tags.join(', ');
    _isRecurring = draft.isRecurring;
    _recurringPattern = draft.recurringPattern;

    // Load description
    _descriptionController.text = draft.description;

    // Set dates/times
    _startDate = draft.startDate;
    _endDate = draft.endDate;

    // Set additional fields
    if (draft.maxAttendees != null) {
      _hasMaxAttendees = true;
      _maxAttendeesController.text = draft.maxAttendees.toString();
    }
    if (draft.ticketPrice != null) {
      _requiresTickets = true;
      _ticketPriceController.text = draft.ticketPrice.toString();
    }

    setState(() {
      _isDraftSaved = true;
    });
  }

  Future<void> _saveDraft() async {
    final description = _descriptionController.text;

    final draft = EventDraft(
      title: _titleController.text,
      description: description,
      category: _selectedCategory,
      startDate: _startDate ?? DateTime.now(),
      endDate: _endDate,
      location: _locationController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      imageFiles: _selectedImages,
      maxAttendees: _hasMaxAttendees ? int.tryParse(_maxAttendeesController.text) : null,
      ticketPrice: _requiresTickets ? double.tryParse(_ticketPriceController.text) : null,
      tags: _tags,
      isRecurring: _isRecurring,
      recurringPattern: _recurringPattern,
      savedAt: DateTime.now(),
    );

    await _formService.saveEventDraft(draft);
    setState(() {
      _isDraftSaved = true;
    });

    if (mounted) {
      CustomSnackBar.showSuccess(context, 'Draft saved successfully!');
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isSignedIn) {
      CustomSnackBar.showError(context, 'Please sign in to create an event');
      return;
    }

    if (_startDate == null || _startTime == null) {
      CustomSnackBar.showError(context, 'Please select start date and time');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final description = _descriptionController.text;
      if (description.trim().isEmpty) {
        CustomSnackBar.showError(context, 'Please enter an event description');
        return;
      }

      // Combine date and time
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final draft = EventDraft(
        title: _titleController.text.trim(),
        description: description,
        category: _selectedCategory,
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim(),
        address: _addressController.text.isEmpty ? null : _addressController.text.trim(),
        imageFiles: _selectedImages,
        maxAttendees: _hasMaxAttendees ? int.tryParse(_maxAttendeesController.text) : null,
        ticketPrice: _requiresTickets ? double.tryParse(_ticketPriceController.text) : null,
        tags: _tags,
        isRecurring: _isRecurring,
        recurringPattern: _recurringPattern,
        savedAt: DateTime.now(),
      );

      final event = await _formService.submitEvent(draft);

      if (!mounted) return;

      CustomSnackBar.showSuccess(context, 'Event published successfully!');
      Navigator.pop(context, event);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, 'Failed to publish event: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
