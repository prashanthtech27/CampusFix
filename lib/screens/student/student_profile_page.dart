import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_page.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() =>
      _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final AuthService _authService = AuthService();

  late Future<dynamic> _profileFuture;

  static const Color primaryColor = Color(0xFF173B70);
  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color orangeColor = Color(0xFFFF8A32);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = _authService.getUserProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _loadProfile();
    });

    await _profileFuture;
  }

  // OPEN EDIT PROFILE PAGE
  Future<void> _openEditProfile(
    Map<String, dynamic> data,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          profileData: data,
        ),
      ),
    );

    if (result == true && mounted) {
      await _refreshProfile();
    }
  }

  // LOGOUT
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from CampusFix?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // PROFILE INFORMATION ITEM
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CONTRIBUTION STATISTICS
  Widget _buildContributionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 9),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ACHIEVEMENT BADGE
  Widget _buildBadge({
    required String title,
    required IconData icon,
    required Color color,
    required bool unlocked,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: unlocked
              ? color.withValues(alpha: 0.09)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 31,
              color: unlocked ? color : Colors.grey.shade400,
            ),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: unlocked ? color : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unlocked ? 'Unlocked' : 'Locked',
              style: TextStyle(
                fontSize: 9,
                color: unlocked ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GAMIFICATION CARD
  Widget _buildGamificationCard(int points) {
    final int level = (points ~/ 50) + 1;

    final String levelName;

    if (level == 1) {
      levelName = 'Newcomer';
    } else if (level == 2) {
      levelName = 'Active Reporter';
    } else if (level == 3) {
      levelName = 'Campus Helper';
    } else if (level == 4) {
      levelName = 'Campus Champion';
    } else {
      levelName = 'Campus Hero';
    }

    final int pointsInCurrentLevel = points % 50;
    

    final double progress = pointsInCurrentLevel / 50;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$points Points',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const Text(
                      'Your contribution points',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.orange,
                  size: 27,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                'Level $level',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                levelName,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.blue,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$points points',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${(level * 50)} points',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STUDENT PROFILE CONTENT
  Widget _buildProfileContent(Map<String, dynamic> data) {
    final String name = data['name']?.toString() ?? 'Student';
    final String usn = data['usn']?.toString() ?? '';

    final String cetNumber =
        data['cetNumber']?.toString() ?? '';

    final String identifier =
        data['loginIdentifier']?.toString() ?? '';

    final String department =
        data['department']?.toString() ?? '';

    final String year = data['year']?.toString() ?? '';

    final String role = data['role']?.toString() ?? 'student';

    final String studentNumber = usn.isNotEmpty
        ? usn
        : cetNumber.isNotEmpty
            ? cetNumber
            : identifier;

    final user = _authService.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please login again.'),
      );
    }

    final complaintsStream = FirebaseFirestore.instance
        .collection('complaints')
        .where('studentUid', isEqualTo: user.uid)
        .snapshots();

    return RefreshIndicator(
      onRefresh: _refreshProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // STUDENT HEADER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor:
                      primaryColor.withValues(alpha: 0.10),
                  child: const Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        studentNumber.isEmpty
                            ? 'Student ID unavailable'
                            : 'USN: $studentNumber',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openEditProfile(data),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // REAL-TIME CONTRIBUTIONS
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: complaintsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Unable to load contribution statistics.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final complaints = snapshot.data?.docs ?? [];

              final int reported = complaints.length;

              final int resolved = complaints.where((doc) {
                final status =
                    doc.data()['status']?.toString().toLowerCase();

                return status == 'resolved';
              }).length;

              final int inProgress = complaints.where((doc) {
                final status =
                    doc.data()['status']?.toString().toLowerCase();

                return status == 'in progress' ||
                    status == 'in_progress';
              }).length;

              final int points = reported * 10;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGamificationCard(points),

                  const SizedBox(height: 22),

                  const Text(
                    'My Contribution',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildContributionCard(
                        title: 'Issues Reported',
                        count: reported,
                        icon: Icons.assignment_outlined,
                        color: Colors.blue,
                      ),
                      _buildContributionCard(
                        title: 'Resolved',
                        count: resolved,
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _buildContributionCard(
                        title: 'In Progress',
                        count: inProgress,
                        icon: Icons.settings,
                        color: orangeColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Achievement Badges',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildBadge(
                        title: 'First Reporter',
                        icon: Icons.emoji_events,
                        color: Colors.orange,
                        unlocked: reported >= 1,
                      ),
                      _buildBadge(
                        title: 'Active User',
                        icon: Icons.shield,
                        color: Colors.green,
                        unlocked: reported >= 5,
                      ),
                      _buildBadge(
                        title: 'Helpful Student',
                        icon: Icons.volunteer_activism,
                        color: Colors.purple,
                        unlocked: resolved >= 3,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 25),

          // PERSONAL INFORMATION
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 14),

          _buildProfileItem(
            icon: Icons.person_outline,
            title: 'Full Name',
            value: name,
          ),

          _buildProfileItem(
            icon: Icons.badge_outlined,
            title: 'USN / CET Number',
            value: studentNumber,
          ),

          _buildProfileItem(
            icon: Icons.school_outlined,
            title: 'Department',
            value: department,
          ),

          _buildProfileItem(
            icon: Icons.calendar_month_outlined,
            title: 'Academic Year',
            value: year,
          ),

          _buildProfileItem(
            icon: Icons.fingerprint,
            title: 'Account Role',
            value: role.toUpperCase(),
          ),

          _buildProfileItem(
            icon: Icons.account_circle_outlined,
            title: 'Login Identifier',
            value: identifier,
          ),

          const SizedBox(height: 12),

          // EDIT PROFILE BUTTON
          OutlinedButton.icon(
            onPressed: () => _openEditProfile(data),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 13),

          // LOGOUT BUTTON
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Center(
            child: Text(
              'CAMPUSFIX',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text('Unable to load profile.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(_loadProfile);
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Student profile not found.'),
            );
          }

          final data = snapshot.data!.data();

          if (data == null) {
            return const Center(
              child: Text('Student profile is empty.'),
            );
          }

          return _buildProfileContent(data);
        },
      ),
    );
  }
}