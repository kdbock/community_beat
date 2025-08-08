// lib/screens/polls/create_poll_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/poll.dart';
import '../../services/poll_service.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  PollCategory _selectedCategory = PollCategory.general;
  bool _allowMultipleVotes = false;
  bool _isAnonymous = false;
  DateTime? _expiresAt;
  
  final List<PollOptionData> _options = [
    PollOptionData(),
    PollOptionData(),
  ];
  
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poll'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createPoll,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'CREATE',
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
              // Basic Information
              _buildBasicInfoSection(),
              
              const SizedBox(height: 24),
              
              // Poll Options
              _buildOptionsSection(),
              
              const SizedBox(height: 24),
              
              // Settings
              _buildSettingsSection(),
              
              const SizedBox(height: 24),
              
              // Preview
              _buildPreviewSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Poll Title *',
                hintText: 'What would you like to ask?',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a poll title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Provide more context for your poll...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<PollCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: PollCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20, color: category.color),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (Optional)',
                hintText: 'community, local, important (comma separated)',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Poll Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_options.length < 6)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Options list
            ..._options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: option.textController,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1} *',
                          hintText: 'Enter option text...',
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter option text';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_options.length > 2) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                      ),
                    ],
                  ],
                ),
              );
            }),
            
            if (_options.length < 2)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'A poll needs at least 2 options.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poll Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Multiple votes
            SwitchListTile(
              title: const Text('Allow Multiple Votes'),
              subtitle: const Text('Users can select multiple options'),
              value: _allowMultipleVotes,
              onChanged: (value) {
                setState(() {
                  _allowMultipleVotes = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Anonymous voting
            SwitchListTile(
              title: const Text('Anonymous Voting'),
              subtitle: const Text('Hide voter identities in results'),
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 16),
            
            // Expiration date
            ListTile(
              title: const Text('Expiration Date (Optional)'),
              subtitle: Text(
                _expiresAt != null
                    ? 'Expires on ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                    : 'No expiration date set',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiresAt != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _expiresAt = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    onPressed: _selectExpirationDate,
                    icon: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_titleController.text.trim().isEmpty || 
        _options.where((o) => o.textController.text.trim().isNotEmpty).length < 2) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mock poll preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedCategory.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedCategory.icon,
                          size: 14,
                          color: _selectedCategory.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedCategory.displayName,
                          style: TextStyle(
                            color: _selectedCategory.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    _titleController.text.trim(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (_descriptionController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _descriptionController.text.trim(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Options preview
                  ..._options
                      .where((o) => o.textController.text.trim().isNotEmpty)
                      .map((option) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _allowMultipleVotes
                                        ? Icons.check_box_outline_blank
                                        : Icons.radio_button_unchecked,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(option.textController.text.trim()),
                                  ),
                                ],
                              ),
                            ),
                          )),
                  
                  const SizedBox(height: 12),
                  
                  // Settings info
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_allowMultipleVotes)
                        Chip(
                          label: const Text('Multiple Votes'),
                          backgroundColor: Colors.blue[50],
                          labelStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                          ),
                        ),
                      if (_isAnonymous)
                        Chip(
                          label: const Text('Anonymous'),
                          backgroundColor: Colors.purple[50],
                          labelStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.purple[700],
                          ),
                        ),
                      if (_expiresAt != null)
                        Chip(
                          label: Text('Expires ${_expiresAt!.day}/${_expiresAt!.month}'),
                          backgroundColor: Colors.orange[50],
                          labelStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addOption() {
    if (_options.length < 6) {
      setState(() {
        _options.add(PollOptionData());
      });
    }
  }

  void _removeOption(int index) {
    if (_options.length > 2) {
      setState(() {
        _options[index].dispose();
        _options.removeAt(index);
      });
    }
  }

  Future<void> _selectExpirationDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(hours: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _expiresAt ?? now.add(const Duration(hours: 24)),
        ),
      );

      if (time != null) {
        setState(() {
          _expiresAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    final validOptions = _options
        .where((o) => o.textController.text.trim().isNotEmpty)
        .toList();

    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 2 options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final pollOptions = validOptions.asMap().entries.map((entry) {
        return PollOption(
          id: 'option_${entry.key}',
          text: entry.value.textController.text.trim(),
          description: entry.value.descriptionController.text.trim().isEmpty
              ? null
              : entry.value.descriptionController.text.trim(),
        );
      }).toList();

      final poll = Poll(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: user.uid,
        creatorName: user.displayName ?? 'Anonymous',
        options: pollOptions,
        createdAt: DateTime.now(),
        expiresAt: _expiresAt,
        allowMultipleVotes: _allowMultipleVotes,
        isAnonymous: _isAnonymous,
        category: _selectedCategory,
        tags: tags,
      );

      await PollService.createPoll(poll);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Poll created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to create poll: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

class PollOptionData {
  final TextEditingController textController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void dispose() {
    textController.dispose();
    descriptionController.dispose();
  }
}