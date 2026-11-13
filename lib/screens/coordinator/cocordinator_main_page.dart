import 'package:flutter/material.dart';

import 'coordinator_dashboard_page.dart';

class CoordinatorMainPage extends StatefulWidget {
  const CoordinatorMainPage({super.key});

  @override
  State<CoordinatorMainPage> createState() =>
      _CoordinatorMainPageState();
}

class _CoordinatorMainPageState
    extends State<CoordinatorMainPage> {
  static const Color primaryColor = Color(0xFF075DD5);


  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    CoordinatorDashboardPage(),
    _PlaceholderPage(
      title: 'Manage Users',
      icon: Icons.people_alt_rounded,
      description: 'Manage students and maintenance staff.',
    ),
    _PlaceholderPage(
      title: 'All Complaints',
      icon: Icons.assignment_rounded,
      description: 'View and manage all campus complaints.',
    ),
    _PlaceholderPage(
      title: 'Analytics',
      icon: Icons.analytics_rounded,
      description: 'Monitor complaint statistics and performance.',
    ),
    _PlaceholderPage(
      title: 'Admin Profile',
      icon: Icons.account_circle_rounded,
      description: 'Manage your administrator profile.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.blueGrey,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        elevation: 12,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF092B65),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 65,
                color: const Color(0xFF075DD5),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF092B65),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}