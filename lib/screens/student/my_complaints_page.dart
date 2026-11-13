import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'complaint_details_page.dart';

class MyComplaintsPage extends StatelessWidget {
  const MyComplaintsPage({super.key});

  static const Color primaryColor = Color(0xFF0866E8);
  static const Color darkColor = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your complaints.'),
        ),
      );
    }

    // Fetch only complaints belonging to the logged-in student.
    final complaintsStream = FirebaseFirestore.instance
        .collection('complaints')
        .where('studentUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Complaints',
          style: TextStyle(
            color: darkColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: darkColor),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: complaintsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load complaints.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final complaints = snapshot.data?.docs ?? [];

          final total = complaints.length;

          final reported = complaints
              .where((c) => c.data()['status'] == 'Reported')
              .length;

          final inProgress = complaints
              .where((c) => c.data()['status'] == 'In Progress')
              .length;

          final resolved = complaints
              .where((c) => c.data()['status'] == 'Resolved')
              .length;

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('complaints')
                  .where('studentUid', isEqualTo: user.uid)
                  .get();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Complaint summary.
                _buildSummary(
                  total,
                  reported,
                  inProgress,
                  resolved,
                ),

                const SizedBox(height: 24),

                const Text(
                  'All Complaints',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),

                const SizedBox(height: 14),

                // Complaint list.
                if (complaints.isEmpty)
                  _buildEmptyState()
                else
                  ...complaints.map((complaint) {
                    return _buildComplaintCard(
                      complaint.data(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ComplaintDetailsPage(
                              complaintDocumentId: complaint.id,
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // COMPLAINT SUMMARY
  // --------------------------------------------------

  Widget _buildSummary(
    int total,
    int reported,
    int inProgress,
    int resolved,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complaint Overview',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _summaryItem(
                'Total',
                total,
                primaryColor,
                Icons.assignment_outlined,
              ),
              _summaryItem(
                'Reported',
                reported,
                Colors.blue,
                Icons.fiber_new,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _summaryItem(
                'In Progress',
                inProgress,
                Colors.orange,
                Icons.pending_actions,
              ),
              _summaryItem(
                'Resolved',
                resolved,
                Colors.green,
                Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 9),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // COMPLAINT CARD
  // --------------------------------------------------

  Widget _buildComplaintCard(
    Map<String, dynamic> data, {
    required VoidCallback onTap,
  }) {
    final status = data['status']?.toString() ?? 'Reported';
    final priority = data['priority']?.toString() ?? 'Medium';

    final statusColor = _getStatusColor(status);

    final createdAt = data['createdAt'];

    final date = createdAt is Timestamp
        ? _formatDate(createdAt.toDate())
        : 'Date unavailable';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['complaintId']?.toString() ??
                            'Unknown ID',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    _statusBadge(status, statusColor),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  data['title']?.toString() ??
                      'Untitled Complaint',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),

                const SizedBox(height: 10),

                _infoRow(
                  Icons.category_outlined,
                  data['category']?.toString() ??
                      'Not specified',
                ),

                const SizedBox(height: 7),

                _infoRow(
                  Icons.location_on_outlined,
                  data['location']?.toString() ??
                      'Location unavailable',
                ),

                const SizedBox(height: 7),

                _infoRow(
                  Icons.calendar_today_outlined,
                  date,
                ),

                const SizedBox(height: 14),

                const Divider(),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Priority: ',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),

                        Text(
                          priority,
                          style: TextStyle(
                            color: _getPriorityColor(priority),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: primaryColor,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // INFORMATION ROW
  // --------------------------------------------------

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // STATUS BADGE
  // --------------------------------------------------

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
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

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 65,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          const Text(
            'No Complaints Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your submitted complaints will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // STATUS COLORS
  // --------------------------------------------------

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange;

      case 'Resolved':
        return Colors.green;

      default:
        return Colors.blue;
    }
  }

  // --------------------------------------------------
  // PRIORITY COLORS
  // --------------------------------------------------

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;

      case 'medium':
        return Colors.blue;

      case 'high':
        return Colors.orange;

      case 'critical':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // --------------------------------------------------
  // DATE FORMAT
  // --------------------------------------------------

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }
}