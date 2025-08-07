import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Form widget for submitting service requests
class ServiceRequestForm extends StatefulWidget {
  final String serviceTitle;
  final Function(ServiceRequestData) onSubmit;

  const ServiceRequestForm({
    super.key,
    required this.serviceTitle,
    required this.onSubmit,
  });

  @override
  State<ServiceRequestForm> createState() => _ServiceRequestFormState();
}

class _ServiceRequestFormState extends State<ServiceRequestForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request: ${widget.serviceTitle}'),
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'fullName',
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'email',
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'phone',
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'address',
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Request Details Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDropdown<String>(
                      name: 'priority',
                      decoration: const InputDecoration(
                        labelText: 'Priority Level *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      ],
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a priority level';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'subject',
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'description',
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Please provide detailed information about your request',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a description';
                        }
                        if (value.trim().length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Scheduling Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred Schedule (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDateTimePicker(
                      name: 'preferredDate',
                      decoration: const InputDecoration(
                        labelText: 'Preferred Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      inputType: InputType.date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDropdown<String>(
                      name: 'preferredTime',
                      decoration: const InputDecoration(
                        labelText: 'Preferred Time',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'morning', child: Text('Morning (8AM - 12PM)')),
                        DropdownMenuItem(value: 'afternoon', child: Text('Afternoon (12PM - 5PM)')),
                        DropdownMenuItem(value: 'evening', child: Text('Evening (5PM - 8PM)')),
                        DropdownMenuItem(value: 'anytime', child: Text('Anytime')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Request'),
            ),
            const SizedBox(height: 16),
            Text(
              'Your request will be reviewed and you will receive a response within 2-3 business days.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      final formData = _formKey.currentState!.value;
      final requestData = ServiceRequestData(
        serviceTitle: widget.serviceTitle,
        fullName: formData['fullName'],
        email: formData['email'],
        phone: formData['phone'],
        address: formData['address'],
        priority: formData['priority'],
        subject: formData['subject'],
        description: formData['description'],
        preferredDate: formData['preferredDate'],
        preferredTime: formData['preferredTime'],
      );

      widget.onSubmit(requestData);
    }
  }
}

class ServiceRequestData {
  final String serviceTitle;
  final String fullName;
  final String email;
  final String phone;
  final String? address;
  final String priority;
  final String subject;
  final String description;
  final DateTime? preferredDate;
  final String? preferredTime;

  ServiceRequestData({
    required this.serviceTitle,
    required this.fullName,
    required this.email,
    required this.phone,
    this.address,
    required this.priority,
    required this.subject,
    required this.description,
    this.preferredDate,
    this.preferredTime,
  });
}