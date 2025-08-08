// lib/screens/public_services_screen.dart

import 'package:flutter/material.dart';
import '../widgets/index.dart';


class PublicServicesScreen extends StatefulWidget {
  const PublicServicesScreen({super.key});

  @override
  State<PublicServicesScreen> createState() => _PublicServicesScreenState();
}

class _PublicServicesScreenState extends State<PublicServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      appBar: AppBar(
        title: const Text(
          'Public Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency),
            onPressed: () {
              _showEmergencyContacts();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Contacts', icon: Icon(Icons.contact_phone)),
            Tab(text: 'Requests', icon: Icon(Icons.build)),
            Tab(text: 'Schedules', icon: Icon(Icons.schedule)),
            Tab(text: 'Forms', icon: Icon(Icons.description)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactsTab(),
          _buildRequestsTab(),
          _buildSchedulesTab(),
          _buildFormsTab(),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    final services = [
      ServiceData(
        title: 'Emergency Services',
        description: 'Police, Fire, Medical Emergency',
        icon: Icons.emergency,
        phone: '911',
        isEmergency: true,
      ),
      ServiceData(
        title: 'City Hall',
        description: 'General city services and administration',
        icon: Icons.account_balance,
        phone: '(555) 123-4568',
        email: 'info@city.gov',
      ),
      ServiceData(
        title: 'Public Works',
        description: 'Road maintenance, utilities, infrastructure',
        icon: Icons.build,
        phone: '(555) 123-4569',
        email: 'works@city.gov',
      ),
      ServiceData(
        title: 'Parks & Recreation',
        description: 'Parks, sports facilities, community events',
        icon: Icons.park,
        phone: '(555) 123-4570',
        email: 'parks@city.gov',
      ),
      ServiceData(
        title: 'Water Department',
        description: 'Water services, billing, quality reports',
        icon: Icons.water_drop,
        phone: '(555) 123-4571',
        email: 'water@city.gov',
      ),
      ServiceData(
        title: 'Building Permits',
        description: 'Construction permits, inspections',
        icon: Icons.construction,
        phone: '(555) 123-4572',
        email: 'permits@city.gov',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ServiceCard(
          title: service.title,
          description: service.description,
          icon: service.icon,
          phone: service.phone,
          email: service.email,
          isExpanded: index == 0, // Expand first item (Emergency)
          onTap: () {
            if (service.title != 'Emergency Services') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceRequestForm(
                    serviceTitle: service.title,
                    onSubmit: (data) {
                      Navigator.pop(context);
                      CustomSnackBar.showSuccess(
                        context,
                        'Service request submitted successfully!',
                      );
                    },
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Service Requests',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Submit and track service requests',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Schedules',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'View department schedules and hours',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Forms',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Download and submit official forms',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContacts() {
    CustomAlertDialog.showInfo(
      context,
      title: 'Emergency Contacts',
      message: 'Police, Fire, Medical: 911\nNon-Emergency Police: (555) 123-4567',
    );
  }
}

class ServiceData {
  final String title;
  final String description;
  final IconData icon;
  final String? phone;
  final String? email;
  final bool isEmergency;

  ServiceData({
    required this.title,
    required this.description,
    required this.icon,
    this.phone,
    this.email,
    this.isEmergency = false,
  });
}