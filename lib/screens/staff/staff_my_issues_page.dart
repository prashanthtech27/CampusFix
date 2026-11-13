import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'staff_complaint_details_page.dart';

class StaffMyIssuesPage extends StatefulWidget {
  const StaffMyIssuesPage({super.key});

  @override
  State<StaffMyIssuesPage> createState() =>
      _StaffMyIssuesPageState();
}

class _StaffMyIssuesPageState extends State<StaffMyIssuesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Tracks complaints currently being processed.
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

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // GET STAFF ASSIGNED COMPLAINTS
  // ==========================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _getAssignedComplaints() {
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
  // ACCEPT COMPLAINT
  // ==========================================

  Future<void> _acceptComplaint(String documentId) async {
    if (_processingComplaints.contains(documentId)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Accept Complaint?',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Do you want to accept this complaint and start working on it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _processingComplaints.add(documentId);
    });

    try {
      await _firestore
          .collection('complaints')
          .doc(documentId)
          .update({
        'status': 'In Progress',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complaint accepted successfully! You can now start working.',
          ),
          backgroundColor: green,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'ACCEPT ERROR: ${e.code} - ${e.message}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to accept complaint: ${e.message}',
          ),
          backgroundColor: red,
        ),
      );
    } catch (e) {
      debugPrint('ACCEPT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while accepting.'),
          backgroundColor: red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingComplaints.remove(documentId);
        });
      }
    }
  }

  // ==========================================
  // DECLINE COMPLAINT
  // ==========================================

  Future<void> _declineComplaint(String documentId) async {
    if (_processingComplaints.contains(documentId)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Decline Complaint?',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to decline this complaint? '
            'It will be returned to the coordinator for reassignment.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.close),
              label: const Text('Decline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _processingComplaints.add(documentId);
    });

    try {
      await _firestore
          .collection('complaints')
          .doc(documentId)
          .update({
        'status': 'Reported',
        'assignedStaffUid': null,
        'assignedStaffName': null,
        'assignedAt': null,
        'declinedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complaint declined and returned to coordinator.',
          ),
          backgroundColor: orange,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'DECLINE ERROR: ${e.code} - ${e.message}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to decline complaint: ${e.message}',
          ),
          backgroundColor: red,
        ),
      );
    } catch (e) {
      debugPrint('DECLINE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while declining.'),
          backgroundColor: red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingComplaints.remove(documentId);
        });
      }
    }
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
  // FILTER COMPLAINTS
  // ==========================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterComplaints(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int tabIndex,
  ) {
    return docs.where((doc) {
      final status = doc.data()['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

      switch (tabIndex) {
        case 0:
          // WAITING FOR STAFF ACCEPTANCE
          return status == 'assigned';

        case 1:
          // CURRENTLY BEING HANDLED
          return status == 'in progress';

        case 2:
          // COMPLETED COMPLAINTS
          return status == 'resolved' ||
              status == 'completed';

        default:
          return false;
      }
    }).toList();
  }

  // ==========================================
  // SORT COMPLAINTS
  // ==========================================

  void _sortComplaints(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    docs.sort((a, b) {
      final aDate = a.data()['createdAt'] as Timestamp?;
      final bDate = b.data()['createdAt'] as Timestamp?;

      return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
        aDate?.millisecondsSinceEpoch ?? 0,
      );
    });
  }

  // ==========================================
  // STATUS BADGE
  // ==========================================

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

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
  // PRIORITY BADGE
  // ==========================================

  Widget _priorityBadge(String priority) {
    final color = _priorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
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

    final priority =
        data['priority']?.toString() ?? 'Medium';

    final status =
        data['status']?.toString() ?? 'Assigned';

    final isAssigned =
        status.toLowerCase().trim() == 'assigned';

    final isProcessing =
        _processingComplaints.contains(documentId);

    final createdAt = data['createdAt'];

    String dateText = 'Date unavailable';

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      dateText =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COMPLAINT ID AND PRIORITY

          Row(
            children: [
              Expanded(
                child: Text(
                  complaintId,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _priorityBadge(priority),
            ],
          ),

          const SizedBox(height: 12),

          // TITLE AND STATUS

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 13),

          // CATEGORY

          _infoRow(
            Icons.category_outlined,
            category,
          ),

          // LOCATION

          _infoRow(
            Icons.location_on_outlined,
            location,
          ),

          // DATE

          _infoRow(
            Icons.calendar_today_outlined,
            dateText,
          ),

          const SizedBox(height: 12),

          const Divider(),

          const SizedBox(height: 10),

          // ACCEPT AND DECLINE BUTTONS
          // Only visible for Assigned complaints.

          if (isAssigned) ...[
            Row(
              children: [
                // DECLINE BUTTON

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _declineComplaint(documentId),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: red,
                      side: const BorderSide(
                        color: red,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ACCEPT BUTTON

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _acceptComplaint(documentId),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          green.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            const SizedBox(height: 10),
          ],

          // VIEW DETAILS

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => StaffComplaintDetailsPage(
                    complaintDocumentId: documentId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: blue,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _emptyState(int tabIndex) {
    String title;
    String subtitle;
    IconData icon;

    switch (tabIndex) {
      case 0:
        title = 'No Assigned Complaints';
        subtitle =
            'New complaints assigned to you will appear here.';
        icon = Icons.assignment_outlined;
        break;

      case 1:
        title = 'No Complaints In Progress';
        subtitle =
            'Complaints you are currently handling will appear here.';
        icon = Icons.autorenew_rounded;
        break;

      default:
        title = 'No Completed Complaints';
        subtitle =
            'Your resolved complaints will appear here.';
        icon = Icons.check_circle_outline_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 65,
              color: Colors.blueGrey.shade300,
            ),

            const SizedBox(height: 15),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COMPLAINT LIST
  // ==========================================

  Widget _complaintList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int tabIndex,
  ) {
    final filtered = _filterComplaints(
      docs,
      tabIndex,
    );

    _sortComplaints(filtered);

    if (filtered.isEmpty) {
      return _emptyState(tabIndex);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        25,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];

        return _complaintCard(
          doc.id,
          doc.data(),
        );
      },
    );
  }

  // ==========================================
  // MAIN BUILD
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
          'My Assigned Issues',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _getAssignedComplaints(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
              'STAFF MY ISSUES ERROR: ${snapshot.error}',
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  'Unable to load complaints.\n'
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

          final docs = snapshot.data?.docs ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _complaintList(docs, 0),
              _complaintList(docs, 1),
              _complaintList(docs, 2),
            ],
          );
        },
      ),
    );
  }
}
