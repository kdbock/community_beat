// lib/screens/business/business_promotions_screen.dart

import 'package:flutter/material.dart';
import '../../models/business_promotion.dart';
import '../../services/business_promotion_service.dart';
import '../../widgets/index.dart';
import 'create_promotion_screen.dart';

class BusinessPromotionsScreen extends StatefulWidget {
  final String businessId;

  const BusinessPromotionsScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessPromotionsScreen> createState() => _BusinessPromotionsScreenState();
}

class _BusinessPromotionsScreenState extends State<BusinessPromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BusinessPromotion> _allPromotions = [];
  List<BusinessPromotion> _activePromotions = [];
  List<BusinessPromotion> _draftPromotions = [];
  List<BusinessPromotion> _expiredPromotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPromotions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final promotions = await BusinessPromotionService.getBusinessPromotions(
        widget.businessId,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _allPromotions = promotions;
          _activePromotions = promotions.where((p) => p.status == PromotionStatus.active).toList();
          _draftPromotions = promotions.where((p) => p.status == PromotionStatus.draft).toList();
          _expiredPromotions = promotions.where((p) => p.isExpired || p.status == PromotionStatus.expired).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading promotions: $e')),
        );
      }
    }
  }

  Future<void> _navigateToCreatePromotion([BusinessPromotion? promotion]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePromotionScreen(
          businessId: widget.businessId,
          existingPromotion: promotion,
        ),
      ),
    );

    if (result == true) {
      _loadPromotions();
    }
  }

  Future<void> _deletePromotion(BusinessPromotion promotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: Text('Are you sure you want to delete "${promotion.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BusinessPromotionService.deletePromotion(promotion.id);
        _loadPromotions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promotion deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting promotion: $e')),
          );
        }
      }
    }
  }

  Future<void> _togglePromotionStatus(BusinessPromotion promotion) async {
    final newStatus = promotion.status == PromotionStatus.active 
        ? PromotionStatus.paused 
        : PromotionStatus.active;

    try {
      await BusinessPromotionService.updatePromotionStatus(promotion.id, newStatus);
      _loadPromotions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promotion ${newStatus.toString().split('.').last}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating promotion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: const Text(
          'Promotions & Deals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'All (${_allPromotions.length})'),
            Tab(text: 'Active (${_activePromotions.length})'),
            Tab(text: 'Draft (${_draftPromotions.length})'),
            Tab(text: 'Expired (${_expiredPromotions.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreatePromotion(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Promotion'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPromotionsList(_allPromotions),
                _buildPromotionsList(_activePromotions),
                _buildPromotionsList(_draftPromotions),
                _buildPromotionsList(_expiredPromotions),
              ],
            ),
    );
  }

  Widget _buildPromotionsList(List<BusinessPromotion> promotions) {
    if (promotions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No promotions yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create your first promotion to attract customers with special offers and deals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreatePromotion(),
                icon: const Icon(Icons.add),
                label: const Text('Create Promotion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromotions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return _buildPromotionCard(promotion);
        },
      ),
    );
  }

  Widget _buildPromotionCard(BusinessPromotion promotion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.typeText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(promotion.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    promotion.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(promotion.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              promotion.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Details row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${promotion.startDate.day}/${promotion.startDate.month} - ${promotion.endDate.day}/${promotion.endDate.month}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                if (promotion.hasUsageLimit) ...[
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${promotion.currentUses}/${promotion.maxUses} used',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),

            // Usage progress bar
            if (promotion.hasUsageLimit) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: promotion.usagePercentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  promotion.usagePercentage > 0.8 ? Colors.red : Theme.of(context).primaryColor,
                ),
              ),
            ],

            // Time remaining
            if (promotion.isCurrentlyActive) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promotion.timeRemaining,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // Tags
            if (promotion.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: promotion.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Analytics (if available)
            if (promotion.viewCount > 0 || promotion.clickCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildAnalyticItem('Views', promotion.viewCount.toString()),
                    const SizedBox(width: 16),
                    _buildAnalyticItem('Clicks', promotion.clickCount.toString()),
                    const SizedBox(width: 16),
                    _buildAnalyticItem('Redeems', promotion.redeemCount.toString()),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _navigateToCreatePromotion(promotion),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                if (promotion.status == PromotionStatus.active || promotion.status == PromotionStatus.paused)
                  TextButton.icon(
                    onPressed: () => _togglePromotionStatus(promotion),
                    icon: Icon(
                      promotion.status == PromotionStatus.active ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(promotion.status == PromotionStatus.active ? 'Pause' : 'Activate'),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _deletePromotion(promotion),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(PromotionStatus status) {
    switch (status) {
      case PromotionStatus.active:
        return Colors.green;
      case PromotionStatus.draft:
        return Colors.grey;
      case PromotionStatus.paused:
        return Colors.orange;
      case PromotionStatus.expired:
        return Colors.red;
      case PromotionStatus.cancelled:
        return Colors.red;
    }
  }
}