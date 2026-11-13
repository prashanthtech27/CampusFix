
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CoordinatorSettingsPage extends StatefulWidget {
  const CoordinatorSettingsPage({super.key});

  @override
  State<CoordinatorSettingsPage> createState() =>
      _CoordinatorSettingsPageState();
}

class _CoordinatorSettingsPageState
    extends State<CoordinatorSettingsPage> {
  static const Color navy = Color(0xFF09213F);
  static const Color blue = Color(0xFF075DD5);
  static const Color background = Color(0xFFF4F7FC);
  static const Color green = Color(0xFF00A879);
  

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool emailNotifications = true;
  bool complaintNotifications = true;
  bool resolutionNotifications = true;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Coordinator Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text('Please log in again.'),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load profile:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data?.data();

                if (data == null) {
                  return const Center(
                    child: Text('Coordinator profile not found.'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _profileCard(
                      data,
                      user.email ?? '',
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle('College Information'),

                    const SizedBox(height: 12),

                    _collegeCard(),

                    const SizedBox(height: 22),

                    _sectionTitle('Complaint Configuration'),

                    const SizedBox(height: 12),

                    _configurationCard(),

                    const SizedBox(height: 22),

                    _sectionTitle('Notification Preferences'),

                    const SizedBox(height: 12),

                    _notificationCard(),

                    const SizedBox(height: 22),

                    _sectionTitle('Account Settings'),

                    const SizedBox(height: 12),

                    _accountCard(),

                    const SizedBox(height: 25),

                    const Center(
                      child: Text(
                        'CAMPUSFIX • East West College of Engineering',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // ==========================================
  // PROFILE CARD
  // ==========================================

  Widget _profileCard(
    Map<String, dynamic> data,
    String email,
  ) {
    final name = data['name']?.toString() ?? 'Coordinator';
    final department =
        data['department']?.toString() ?? 'Administration';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF172554),
            Color(0xFF075DD5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 34,
              color: navy,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.business_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                department,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Chip(
            label: Text(
              'COORDINATOR',
              style: TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COLLEGE INFORMATION
  // ==========================================

  Widget _collegeCard() {
    return _card(
      children: const [
        ListTile(
          leading: Icon(
            Icons.account_balance_rounded,
            color: blue,
          ),
          title: Text(
            'East West College of Engineering',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text('Institution registered with CampusFix'),
        ),
        Divider(),
        ListTile(
          leading: Icon(
            Icons.location_on_outlined,
            color: blue,
          ),
          title: Text('College Location'),
          subtitle: Text('Bengaluru, Karnataka'),
        ),
        Divider(),
        ListTile(
          leading: Icon(
            Icons.apps_rounded,
            color: blue,
          ),
          title: Text('Application'),
          subtitle: Text('CampusFix – Campus Issue Management'),
        ),
      ],
    );
  }

  // ==========================================
  // COMPLAINT CONFIGURATION
  // ==========================================

  Widget _configurationCard() {
    return _card(
      children: [
        _settingTile(
          Icons.category_rounded,
          'Complaint Categories',
          'View supported campus issue categories',
          () => _showInformation(
            'Complaint Categories',
            'Electrical, Plumbing, Furniture, '
            'Infrastructure, IT & Network and Cleanliness.',
          ),
        ),
        const Divider(),
        _settingTile(
          Icons.flag_rounded,
          'Priority Levels',
          'View complaint urgency levels',
          () => _showInformation(
            'Priority Levels',
            'Low, Medium, High and Critical.',
          ),
        ),
      ],
    );
  }

  // ==========================================
  // NOTIFICATION PREFERENCES
  // ==========================================

  Widget _notificationCard() {
    return _card(
      children: [
        SwitchListTile(
          secondary: const Icon(
            Icons.email_outlined,
            color: blue,
          ),
          title: const Text('Email Notifications'),
          subtitle: const Text(
            'Receive notification preferences in the app.',
          ),
          value: emailNotifications,
          activeThumbColor: green,
          onChanged: (value) {
            setState(() {
              emailNotifications = value;
            });
          },
        ),
        const Divider(),
        SwitchListTile(
          secondary: const Icon(
            Icons.assignment_outlined,
            color: blue,
          ),
          title: const Text('New Complaint Alerts'),
          subtitle: const Text(
            'Show alerts for newly submitted complaints.',
          ),
          value: complaintNotifications,
          activeThumbColor: green,
          onChanged: (value) {
            setState(() {
              complaintNotifications = value;
            });
          },
        ),
        const Divider(),
        SwitchListTile(
          secondary: const Icon(
            Icons.task_alt_rounded,
            color: blue,
          ),
          title: const Text('Resolution Alerts'),
          subtitle: const Text(
            'Show alerts when complaints are resolved.',
          ),
          value: resolutionNotifications,
          activeThumbColor: green,
          onChanged: (value) {
            setState(() {
              resolutionNotifications = value;
            });
          },
        ),
      ],
    );
  }

  // ==========================================
  // ACCOUNT SETTINGS
  // ==========================================

  Widget _accountCard() {
    return _card(
      children: [
        _settingTile(
          Icons.lock_outline_rounded,
          'Change Password',
          'Update your Firebase account password',
          _changePassword,
        ),
        const Divider(),
        _settingTile(
          Icons.logout_rounded,
          'Logout',
          'Sign out of your coordinator account',
          _confirmLogout,
          color: Colors.red,
        ),
      ],
    );
  }

  // ==========================================
  // CHANGE PASSWORD
  // ==========================================

  Future<void> _changePassword() async {
    final email = _auth.currentUser?.email;

    if (email == null) return;

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showMessage(
        'Password reset instructions have been sent to your registered email.',
        green,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ?? 'Unable to send password reset email.',
        Colors.red,
      );
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _auth.signOut();
    }
  }

  // ==========================================
  // REUSABLE COMPONENTS
  // ==========================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: navy,
      ),
    );
  }

  Widget _card({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color color = blue,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 15,
      ),
      onTap: onTap,
    );
  }

  // ==========================================
  // INFORMATION DIALOG
  // ==========================================

  void _showInformation(
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // MESSAGE
  // ==========================================

  void _showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
