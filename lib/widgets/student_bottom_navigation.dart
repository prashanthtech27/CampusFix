import 'package:flutter/material.dart';

class StudentBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const StudentBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const Color primaryBlue = Color(0xFF0866E8);
  static const Color secondaryColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemSelected,

      type: BottomNavigationBarType.fixed,

      backgroundColor: Colors.white,
      elevation: 10,

      selectedItemColor: primaryBlue,
      unselectedItemColor: secondaryColor,

      selectedFontSize: 11,
      unselectedFontSize: 11,

      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),

      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
      ),

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Complaints',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 28),
          activeIcon: Icon(Icons.add_circle, size: 28),
          label: 'Report',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}