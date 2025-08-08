import 'package:flutter/material.dart';

/// Custom bottom navigation bar for navigating between main screens
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper),
          label: 'News',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'Directory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.announcement),
          label: 'Bulletin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.poll),
          label: 'Polls',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Map',
        ),
      ],
    );
  }
}