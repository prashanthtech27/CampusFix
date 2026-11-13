
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'my_complaints_page.dart';
import 'report_issue_page.dart';
import 'notifications_page.dart';
import 'complaint_details_page.dart';
import 'student_profile_page.dart';

import '../../services/auth_service.dart';

import '../../widgets/student_app_bar.dart';
import '../../widgets/student_profile_header.dart';
import '../../widgets/complaint_status_card.dart';
import '../../widgets/recent_complaint_card.dart';
import '../../widgets/student_bottom_navigation.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final AuthService _authService = AuthService();

  late Future<Map<String, dynamic>> _studentProfile;

  int _selectedIndex = 0;

  static const Color primaryBlue = Color(0xFF0866E8);
  static const Color darkBlue = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _studentProfile = _loadStudentProfile();
  }

  // FETCH STUDENT PROFILE

  Future<Map<String, dynamic>> _loadStudentProfile() async {
    final document = await _authService.getUserProfile();

    if (!document.exists || document.data() == null) {
      throw Exception('Student profile not found.');
    }

    return document.data()!;
  }

  // REFRESH STUDENT PROFILE

  Future<void> _refreshProfile() async {
    setState(() {
      _studentProfile = _loadStudentProfile();
    });

    await _studentProfile;
  }

  // DASHBOARD ACTION

  void _onDashboardTap() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  // BOTTOM NAVIGATION ACTION

  void _onBottomNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyComplaintsPage(),
          ),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportIssuePage(),
          ),
        );
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsPage(),
          ),
        );
        break;

      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentProfilePage(),
          ),
        );
        break;
    }
  }

  // REPORT NEW ISSUE

  void _onReportIssueTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportIssuePage(),
      ),
    );
  }

  // VIEW ALL COMPLAINTS

  void _onViewAllTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyComplaintsPage(),
      ),
    );
  }

  // OPEN COMPLAINT DETAILS

  void _openComplaintDetails(String documentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintDetailsPage(
          complaintDocumentId: documentId,
        ),
      ),
    );
  }

  // FORMAT DATE

  String _formatDate(dynamic timestamp) {
    if (timestamp is! Timestamp) {
      return 'Date unavailable';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // BUILD LIVE COMPLAINT DASHBOARD

  Widget _buildComplaintDashboard(String studentUid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('studentUid', isEqualTo: studentUid)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Unable to load complaints.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(25),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            ),
          );
        }

        final complaints = snapshot.data?.docs ?? [];

       // CALCULATE COMPLAINT COUNTS

int reportedCount = 0;
int inProgressCount = 0;
int resolvedCount = 0;

for (final complaint in complaints) {
  final data = complaint.data();

  final status = data['status']
      ?.toString()
      .trim()
      .toLowerCase() ?? '';

  switch (status) {
    case 'reported':
    case 'assigned':
      reportedCount++;
      break;

    case 'in progress':
      inProgressCount++;
      break;

    case 'resolved':
    case 'closed':
      resolvedCount++;
      break;
  }
}

        // SORT COMPLAINTS BY DATE

        final sortedComplaints = [...complaints];

        sortedComplaints.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          final aDate = aTime is Timestamp
              ? aTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          final bDate = bTime is Timestamp
              ? bTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });

        // GET LATEST THREE COMPLAINTS

        final recentComplaints = sortedComplaints.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COMPLAINT SUMMARY TITLE

            const Text(
              'My Complaint Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 14),

            // COMPLAINT STATUS CARDS

            Row(
              children: [
                ComplaintStatusCard(
                  title: 'Reported',
                  count: reportedCount,
                  color: primaryBlue,
                  icon: Icons.assignment_outlined,
                ),

                const SizedBox(width: 10),

                ComplaintStatusCard(
                  title: 'In Progress',
                  count: inProgressCount,
                  color: const Color(0xFFFFA500),
                  icon: Icons.pending_actions,
                ),

                const SizedBox(width: 10),

                ComplaintStatusCard(
                  title: 'Resolved',
                  count: resolvedCount,
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // REPORT NEW ISSUE BUTTON

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _onReportIssueTap,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  'Report New Issue',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // RECENT COMPLAINTS HEADER

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Complaints',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),

                TextButton(
                  onPressed: _onViewAllTap,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // RECENT COMPLAINTS LIST

            if (recentComplaints.isEmpty)
              _buildEmptyComplaintState()
            else
              ...recentComplaints.map((complaint) {
                final data = complaint.data();

                return RecentComplaintCard(
                  title: data['title']?.toString() ?? 'Untitled Issue',
                  location: data['location']?.toString() ?? 'Unknown',
                  date: _formatDate(data['createdAt']),
                  status: data['status']?.toString() ?? 'Reported',
                  category: data['category']?.toString() ?? 'Other',

                  onTap: () {
                    _openComplaintDetails(complaint.id);
                  },
                );
              }),

            const SizedBox(height: 25),
          ],
        );
      },
    );
  }

  // EMPTY COMPLAINT STATE

  Widget _buildEmptyComplaintState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 55,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            'No Complaints Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your reported campus issues will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // APP BAR

      appBar: StudentAppBar(
        onDashboardTap: _onDashboardTap,
      ),

      // STUDENT HOMEPAGE BODY

      body: FutureBuilder<Map<String, dynamic>>(
        future: _studentProfile,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Unable to load student profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _studentProfile = _loadStudentProfile();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final student = snapshot.data!;

          final String name =
              student['name']?.toString() ?? 'Student';

          final String usn =
              student['usn']?.toString() ??
              student['cetNumber']?.toString() ??
              '';

          final String department =
              student['department']?.toString() ?? '';

          final String? profileImageUrl =
              student['profileImageUrl']?.toString();

          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Please log in again.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshProfile,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STUDENT PROFILE HEADER

                  StudentProfileHeader(
                    name: name,
                    usn: usn,
                    department: department,
                    profileImageUrl: profileImageUrl,
                  ),

                  const SizedBox(height: 25),

                  // LIVE COMPLAINT DASHBOARD

                  _buildComplaintDashboard(user.uid),
                ],
              ),
            ),
          );
        },
      ),

      // FIXED BOTTOM NAVIGATION

      bottomNavigationBar: StudentBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemSelected: _onBottomNavigationTap,
      ),
    );
  }
}
