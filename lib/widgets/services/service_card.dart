import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card widget for displaying public service departments
class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? phone;
  final String? email;
  final String? website;
  final List<ServiceContact>? contacts;
  final VoidCallback? onTap;
  final bool isExpanded;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.phone,
    this.email,
    this.website,
    this.contacts,
    this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return _buildExpansionTile(context);
    } else {
      return _buildCard(context);
    }
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contacts != null && contacts!.isNotEmpty) ...[
                  Text(
                    'Contacts',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...contacts!.map((contact) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.position),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (contact.phone != null)
                          IconButton(
                            icon: const Icon(Icons.phone),
                            onPressed: () => _launchPhone(contact.phone!),
                          ),
                        if (contact.email != null)
                          IconButton(
                            icon: const Icon(Icons.email),
                            onPressed: () => _launchEmail(contact.email!),
                          ),
                      ],
                    ),
                  )),
                  const Divider(),
                ],
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (phone != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launchPhone(phone!),
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        if (phone != null && email != null) const SizedBox(width: 8),
        if (email != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launchEmail(email!),
              icon: const Icon(Icons.email, size: 16),
              label: const Text('Email'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        if ((phone != null || email != null) && website != null) const SizedBox(width: 8),
        if (website != null)
          Expanded(
            child: TextButton.icon(
              onPressed: () => _launchWebsite(website!),
              icon: const Icon(Icons.web, size: 16),
              label: const Text('Website'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String website) async {
    final Uri uri = Uri.parse(website);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class ServiceContact {
  final String name;
  final String position;
  final String? phone;
  final String? email;

  ServiceContact({
    required this.name,
    required this.position,
    this.phone,
    this.email,
  });
}