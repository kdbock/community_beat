import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/custom_image.dart';

/// Card widget for displaying business information
class BusinessCard extends StatelessWidget {
  final String name;
  final String description;
  final String? imageUrl;
  final String? phone;
  final String? email;
  final String? website;
  final String category;
  final double? rating;
  final bool hasDeals;
  final bool isNew;
  final VoidCallback? onTap;

  const BusinessCard({
    super.key,
    required this.name,
    required this.description,
    this.imageUrl,
    this.phone,
    this.email,
    this.website,
    required this.category,
    this.rating,
    this.hasDeals = false,
    this.isNew = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business logo/image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImage(
                      imageUrl: imageUrl,
                      width: 60,
                      height: 60,
                      placeholder: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.business,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Business info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Badges
                            if (isNew) _buildBadge(context, 'NEW', Colors.green),
                            if (hasDeals) _buildBadge(context, 'DEAL', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (rating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < rating!.floor()
                                      ? Icons.star
                                      : index < rating!
                                          ? Icons.star_half
                                          : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                              const SizedBox(width: 4),
                              Text(
                                rating!.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
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
}