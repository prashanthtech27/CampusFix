import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'staff_profile_page.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';
import '../student/complaint_details_page.dart';
import 'staff_my_issues_page.dart';
import 'staff_notifications_page.dart';
class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() =>
      _StaffDashboardPageState();
}

class _StaffDashboardPageState
    extends State<StaffDashboardPage> {
  final AuthService _authService = AuthService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _staffName = 'Staff Member';
  String _department = 'Maintenance Staff';

  int _selectedIndex = 0;
final Set<String> _processingComplaints = {};
  static const Color navy = Color(0xFF092B65);
  static const Color blue = Color(0xFF075DD5);
  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF159957);
  static const Color red = Color(0xFFE84B3C);

  static const Color background = Color(0xFFF3F6FC);

  @override
  void initState() {
    super.initState();
    _loadStaffProfile();
  }

  // ==========================================
  // LOAD STAFF PROFILE
  // ==========================================

  Future<void> _loadStaffProfile() async {
    try {
      final profile = await _authService.getUserProfile();

      if (!mounted || !profile.exists) return;

      final data = profile.data();

      setState(() {
        _staffName =
            data?['name']?.toString() ?? 'Staff Member';

        _department =
            data?['department']?.toString() ??
                'Maintenance Staff';
      });
    } catch (e) {
      debugPrint('STAFF PROFILE ERROR: $e');
    }
  }

  // ==========================================
  // GET ASSIGNED COMPLAINTS
  // ==========================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _assignedComplaintsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('complaints')
        .where(
          'assignedStaffUid',
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
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

    if (confirm != true) return;

    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // ==========================================
  // STATUS COLOR
  // ==========================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
      case 'reported':
        return blue;

      case 'in progress':
        return orange;

      case 'resolved':
      case 'completed':
        return green;

      default:
        return Colors.grey;
    }
  }

  // ==========================================
  // PRIORITY COLOR
  // ==========================================

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return red;

      case 'high':
        return Colors.deepOrange;

      case 'medium':
        return orange;

      case 'low':
        return green;

      default:
        return Colors.grey;
    }
  }

  // ==========================================
  // REUSABLE SECTION TITLE
  // ==========================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: navy,
      ),
    );
  }

  // ==========================================
  // WELCOME CARD
  // ==========================================

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF092B65),
            Color(0xFF075DD5),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.engineering_rounded,
              color: navy,
              size: 35,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _staffName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STATISTICS CARD
  // ==========================================

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 29,
            ),

            const SizedBox(height: 12),

            Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PRIORITY BADGE
  // ==========================================

  Widget _priorityBadge(String priority) {
    final color = _priorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // STATUS BADGE
  // ==========================================

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // INFORMATION ROW
  // ==========================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blueGrey,
            size: 17,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }Future<void> _acceptComplaint(String documentId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Accept Complaint?'),
      content: const Text(
        'Do you want to accept this complaint and start working on it?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Accept'),
        ),
      ],
    ),
  );

  if (confirm != true || !mounted) return;

  setState(() => _processingComplaints.add(documentId));

  try {
    await _firestore.collection('complaints').doc(documentId).update({
      'status': 'In Progress',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint accepted successfully!'),
        backgroundColor: green,
      ),
    );
  } on FirebaseException catch (e) {
    debugPrint('ACCEPT ERROR: ${e.code} - ${e.message}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to accept: ${e.message}'),
          backgroundColor: red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _processingComplaints.remove(documentId));
    }
  }
}
Future<void> _declineComplaint(String documentId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Decline Complaint?'),
      content: const Text(
        'Are you sure you want to decline this complaint? '
        'It will be returned to the coordinator for reassignment.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Decline'),
        ),
      ],
    ),
  );

  if (confirm != true || !mounted) return;

  setState(() => _processingComplaints.add(documentId));

  try {
    await _firestore.collection('complaints').doc(documentId).update({
      'status': 'Reported',
      'assignedStaffUid': null,
      'assignedStaffName': null,
      'assignedAt': null,
      'declinedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint declined and returned to coordinator.'),
        backgroundColor: orange,
      ),
    );
  } on FirebaseException catch (e) {
    debugPrint('DECLINE ERROR: ${e.code} - ${e.message}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to decline: ${e.message}'),
          backgroundColor: red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _processingComplaints.remove(documentId));
    }
  }
}

  // ==========================================
  // COMPLAINT CARD
  // ==========================================

  Widget _complaintCard(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final complaintId =
        data['complaintId']?.toString() ?? documentId;

    final title =
        data['title']?.toString() ?? 'Untitled Complaint';

    final category =
        data['category']?.toString() ?? 'General';

    final location =
        data['location']?.toString() ?? 'Not specified';

    final studentName =
        data['studentName']?.toString() ?? 'Student';

    final status =
        data['status']?.toString() ?? 'Assigned';

    final priority =
        data['priority']?.toString() ?? 'Medium';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COMPLAINT ID AND STATUS

          Row(
            children: [
              Expanded(
                child: Text(
                  complaintId,
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 13),

          // TITLE AND PRIORITY

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              _priorityBadge(priority),
            ],
          ),

          const SizedBox(height: 15),

          _infoRow(
            Icons.person_outline,
            studentName,
          ),

          _infoRow(
            Icons.category_outlined,
            category,
          ),

          _infoRow(
            Icons.location_on_outlined,
            location,
          ),

          _infoRow(
            Icons.flag_outlined,
            'Priority: $priority',
          ),

          const SizedBox(height: 12),

          // VIEW DETAILS BUTTON

          // STAFF ACTION BUTTONS

if (status.toLowerCase() == 'assigned') ...[
  Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _processingComplaints.contains(documentId)
              ? null
              : () => _declineComplaint(documentId),
          icon: const Icon(Icons.close),
          label: const Text('Decline'),
          style: OutlinedButton.styleFrom(
            foregroundColor: red,
            side: const BorderSide(color: red),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _processingComplaints.contains(documentId)
              ? null
              : () => _acceptComplaint(documentId),
          icon: const Icon(Icons.check),
          label: const Text('Accept'),
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    ],
  ),

  const SizedBox(height: 10),
],

if (_processingComplaints.contains(documentId))
  const Center(
    child: Padding(
      padding: EdgeInsets.all(8),
      child: CircularProgressIndicator(),
    ),
  ),

SizedBox(
  width: double.infinity,
  height: 46,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ComplaintDetailsPage(
            complaintDocumentId: documentId,
          ),
        ),
      );
    },
    icon: const Icon(Icons.visibility_outlined, size: 18),
    label: const Text('View Details'),
    style: OutlinedButton.styleFrom(
      foregroundColor: blue,
      side: const BorderSide(color: blue),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY COMPLAINT VIEW
  // ==========================================

  Widget _emptyComplaints() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 55,
            color: Colors.blueGrey,
          ),

          SizedBox(height: 12),

          Text(
            'No complaints assigned yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
              fontSize: 15,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'New complaints assigned by the coordinator '
            'will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================
void _onNavigationTap(int index) {
  if (index == 0) {
    setState(() {
      _selectedIndex = 0;
    });
    return;
  }

  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const StaffMyIssuesPage(),
      ),
    );
    return;
  }

  if (index == 3) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const StaffProfilePage(),
      ),
    );
    return;
  }

  if (index == 2) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const StaffNotificationsPage(),
    ),
  );
  return;
}
}

  Widget _bottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavigationTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: blue,
      unselectedItemColor: Colors.blueGrey,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          label: 'My Issues',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none_rounded),
          label: 'Notifications',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  // ==========================================
  // MAIN DASHBOARD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CAMPUSFIX',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _assignedComplaintsStream(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  'Unable to load assigned complaints.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          final complaints = documents.toList();

          complaints.sort((a, b) {
            final aTime =
                a.data()['createdAt'] as Timestamp?;

            final bTime =
                b.data()['createdAt'] as Timestamp?;

            return (bTime?.millisecondsSinceEpoch ?? 0)
                .compareTo(
              aTime?.millisecondsSinceEpoch ?? 0,
            );
          });

          final total = complaints.length;

          final reported = complaints.where((doc) {
            final status = doc.data()['status']
                ?.toString()
                .toLowerCase();

            return status == 'reported' ||
                status == 'assigned';
          }).length;

          final inProgress = complaints.where((doc) {
            return doc.data()['status'] == 'In Progress';
          }).length;

          
final resolved = complaints.where((doc) {
  final status = doc.data()['status']
      ?.toString()
      .trim()
      .toLowerCase();

  return status == 'resolved' || status == 'closed';
}).length;
          return RefreshIndicator(
            onRefresh: _loadStaffProfile,

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                25,
              ),
              children: [
                // WELCOME CARD

                _welcomeCard(),

                const SizedBox(height: 27),

                // OVERVIEW

                _sectionTitle('Complaint Overview'),

                const SizedBox(height: 15),

                Row(
                  children: [
                    _statCard(
                      title: 'Assigned',
                      count: total,
                      icon: Icons.assignment_rounded,
                      color: blue,
                    ),

                    _statCard(
                      title: 'Reported',
                      count: reported,
                      icon: Icons.warning_rounded,
                      color: orange,
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                Row(
                  children: [
                    _statCard(
                      title: 'In Progress',
                      count: inProgress,
                      icon: Icons.autorenew_rounded,
                      color: orange,
                    ),

                    _statCard(
                      title: 'Completed',
                      count: resolved,
                      icon: Icons.check_circle_rounded,
                      color: green,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ASSIGNED COMPLAINTS

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _sectionTitle(
                        'My Assigned Complaints',
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        _onNavigationTap(1);
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (complaints.isEmpty)
                  _emptyComplaints(),

                ...complaints.map(
                  (doc) => _complaintCard(
                    doc.id,
                    doc.data(),
                  ),
                ),

                const SizedBox(height: 15),

                // FOOTER

                const Center(
                  child: Text(
                    'CAMPUSFIX • Maintenance Staff Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: _bottomNavigation(),
    );
  }
}
