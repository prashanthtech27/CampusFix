import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CoordinatorAssignmentsPage extends StatefulWidget {
  const CoordinatorAssignmentsPage({super.key});

  @override
  State<CoordinatorAssignmentsPage> createState() =>
      _CoordinatorAssignmentsPageState();
}

class _CoordinatorAssignmentsPageState
    extends State<CoordinatorAssignmentsPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String selectedStatus = 'All';
  String selectedAssignment = 'All';

  bool _isAssigning = false;

  static const Color navy = Color(0xFF172554);
  static const Color blue = Color(0xFF075DD5);
  static const Color green = Color(0xFF159957);
  static const Color orange = Color(0xFFFF9800);

  final List<String> statuses = [
    'All',
    'Reported',
    'Assigned',
    'In Progress',
    'Resolved',
  ];

  final List<String> assignmentFilters = [
    'All',
    'Assigned',
    'Unassigned',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // MAIN PAGE
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'Assignment Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('complaints')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load assignments:\n${snapshot.error}',
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

          final allComplaints = documents.map((doc) {
            return <String, dynamic>{
              'documentId': doc.id,
              ...doc.data(),
            };
          }).toList();

          // ======================================
          // ASSIGNMENT STATISTICS
          // ======================================

          final total = allComplaints.length;

          final assigned = allComplaints.where((item) {
            final uid = item['assignedStaffUid'];

            return uid != null &&
                uid.toString().isNotEmpty;
          }).length;

          final unassigned = total - assigned;

          final inProgress = allComplaints.where((item) {
            return item['status'] == 'In Progress';
          }).length;

          final resolved = allComplaints.where((item) {
            return item['status'] == 'Resolved';
          }).length;

          // ======================================
          // FILTER COMPLAINTS
          // ======================================

          final search = _searchController.text
              .trim()
              .toLowerCase();

          final filteredComplaints =
              allComplaints.where((item) {
            final complaintId =
                (item['complaintId'] ?? '')
                    .toString()
                    .toLowerCase();

            final title =
                (item['title'] ?? '')
                    .toString()
                    .toLowerCase();

            final staffName =
                (item['assignedStaffName'] ?? '')
                    .toString()
                    .toLowerCase();

            final status =
                item['status']?.toString() ?? 'Reported';

            final uid = item['assignedStaffUid'];

            final isAssigned = uid != null &&
                uid.toString().isNotEmpty;

            final searchMatches =
                search.isEmpty ||
                complaintId.contains(search) ||
                title.contains(search) ||
                staffName.contains(search);

            final statusMatches =
                selectedStatus == 'All' ||
                status == selectedStatus;

            final assignmentMatches =
                selectedAssignment == 'All' ||
                (selectedAssignment == 'Assigned' &&
                    isAssigned) ||
                (selectedAssignment == 'Unassigned' &&
                    !isAssigned);

            return searchMatches &&
                statusMatches &&
                assignmentMatches;
          }).toList();

          // ======================================
          // SORT NEWEST FIRST
          // ======================================

          filteredComplaints.sort((a, b) {
            final aDate = a['createdAt'] as Timestamp?;
            final bDate = b['createdAt'] as Timestamp?;

            return (bDate?.millisecondsSinceEpoch ?? 0)
                .compareTo(
              aDate?.millisecondsSinceEpoch ?? 0,
            );
          });

          return RefreshIndicator(
            onRefresh: () async {
              await _firestore
                  .collection('complaints')
                  .get(
                    const GetOptions(
                      source: Source.server,
                    ),
                  );
            },

            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // PAGE HEADING

                const Text(
                  'Assignment Overview',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Monitor and manage campus complaint assignments.',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                // STATISTICS

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.65,

                  children: [
                    _statCard(
                      'Total Complaints',
                      total.toString(),
                      Icons.assignment_rounded,
                      blue,
                    ),

                    _statCard(
                      'Assigned',
                      assigned.toString(),
                      Icons.person_rounded,
                      green,
                    ),

                    _statCard(
                      'Unassigned',
                      unassigned.toString(),
                      Icons.person_off_rounded,
                      orange,
                    ),

                    _statCard(
                      'In Progress',
                      inProgress.toString(),
                      Icons.pending_actions_rounded,
                      Colors.purple,
                    ),

                    _statCard(
                      'Resolved',
                      resolved.toString(),
                      Icons.task_alt_rounded,
                      green,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // SEARCH

                const Text(
                  'Search Assignments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _searchController,

                  decoration: InputDecoration(
                    hintText:
                        'Search complaint ID, title or staff...',

                    prefixIcon: const Icon(
                      Icons.search,
                    ),

                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),

                  onChanged: (_) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 20),

                // FILTERS

                const Text(
                  'Filter Assignments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _filterDropdown(
                        'Status',
                        selectedStatus,
                        statuses,
                        (value) {
                          if (value == null) return;

                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _filterDropdown(
                        'Assignment',
                        selectedAssignment,
                        assignmentFilters,
                        (value) {
                          if (value == null) return;

                          setState(() {
                            selectedAssignment = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ASSIGNMENT LIST HEADING

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [
                    const Text(
                      'Complaint Assignments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),

                    Text(
                      '${filteredComplaints.length} records',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (filteredComplaints.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: Text(
                        'No assignments found.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredComplaints.map((complaint) {
                    return _assignmentCard(complaint);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // STAT CARD
  // ==========================================

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor:
                color.withValues(alpha: 0.12),

            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey,
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
  // FILTER DROPDOWN
  // ==========================================

  Widget _filterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,

      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: onChanged,
    );
  }

  // ==========================================
  // ASSIGNMENT CARD
  // ==========================================

  Widget _assignmentCard(Map<String, dynamic> data) {
    final documentId = data['documentId'].toString();

    final complaintId =
        data['complaintId']?.toString() ?? documentId;

    final title =
        data['title']?.toString() ?? 'Untitled Complaint';

    final category =
        data['category']?.toString() ?? 'Other';

    final location =
        data['location']?.toString() ?? 'Not specified';

    final priority =
        data['priority']?.toString() ?? 'Medium';

    final status =
        data['status']?.toString() ?? 'Reported';

    final staffUid =
        data['assignedStaffUid']?.toString();

    final staffName =
        data['assignedStaffName']?.toString();

    final isAssigned =
        staffUid != null && staffUid.isNotEmpty;

    // Assignment is allowed only before acceptance.
    final canAssign =
        status == 'Reported' || status == 'Assigned';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),

      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // COMPLAINT ID AND PRIORITY

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                Expanded(
                  child: Text(
                    complaintId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                ),

                _badge(
                  priority,
                  _priorityColor(priority),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text('Category: $category'),

            Text('Location: $location'),

            const SizedBox(height: 13),

            // ASSIGNED STAFF DETAILS

            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: isAssigned
                    ? const Color(0xFFEAF7EF)
                    : const Color(0xFFFFF5E5),

                borderRadius: BorderRadius.circular(10),
              ),

              child: Row(
                children: [
                  Icon(
                    isAssigned
                        ? Icons.person_rounded
                        : Icons.person_off_rounded,

                    color: isAssigned
                        ? green
                        : orange,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          isAssigned
                              ? staffName ?? 'Assigned Staff'
                              : 'Awaiting Assignment',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAssigned
                                ? green
                                : orange,
                          ),
                        ),

                        Text(
                          isAssigned
                              ? 'Staff member assigned'
                              : 'No maintenance staff assigned',

                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // STATUS AND ACTION

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                Flexible(
                  child: _badge(
                    status,
                    _statusColor(status),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton.icon(
                  onPressed: canAssign && !_isAssigning
                      ? () {
                          _assignStaff(
                            documentId,
                            data,
                          );
                        }
                      : null,

                  icon: Icon(
                    isAssigned
                        ? Icons.swap_horiz
                        : Icons.person_add_alt_1,
                    size: 17,
                  ),

                  label: Text(
                    isAssigned ? 'Reassign' : 'Assign',
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            if (!canAssign)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Assignment is locked because work has started or the complaint is resolved.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ASSIGN / REASSIGN STAFF
  // ==========================================

  Future<void> _assignStaff(
    String complaintDocumentId,
    Map<String, dynamic> complaintData,
  ) async {
    if (_isAssigning) return;

    final currentStatus =
        complaintData['status']?.toString() ?? 'Reported';

    if (currentStatus != 'Reported' &&
        currentStatus != 'Assigned') {
      _showMessage(
        'Only Reported or Assigned complaints can be assigned.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      // LOAD STAFF ACCOUNTS

      final staffSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();

      if (!mounted) return;

      if (staffSnapshot.docs.isEmpty) {
        _showMessage(
          'No maintenance staff accounts found.',
          Colors.orange,
        );
        return;
      }

      String? selectedStaffUid =
          complaintData['assignedStaffUid']?.toString();

      // STAFF SELECTION DIALOG

      final selectedStaff = await showDialog<
          QueryDocumentSnapshot<Map<String, dynamic>>>(
        context: context,

        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Assign Maintenance Staff',
                ),

                content: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Text(
                      'Select a maintenance staff member.',
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue: staffSnapshot.docs.any(
                        (staff) => staff.id == selectedStaffUid,
                      )
                          ? selectedStaffUid
                          : null,

                      isExpanded: true,

                      decoration: const InputDecoration(
                        labelText: 'Select Staff',
                        border: OutlineInputBorder(),
                      ),

                      items: staffSnapshot.docs.map((staff) {
                        final staffData = staff.data();

                        final name =
                            staffData['name']?.toString() ??
                                'Unknown';

                        final department =
                            staffData['department']?.toString() ??
                                'General';

                        return DropdownMenuItem<String>(
                          value: staff.id,

                          child: Text(
                            '$name ($department)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setDialogState(() {
                          selectedStaffUid = value;
                        });
                      },
                    ),
                  ],
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton(
                    onPressed: selectedStaffUid == null
                        ? null
                        : () {
                            final staff =
                                staffSnapshot.docs.firstWhere(
                              (doc) =>
                                  doc.id == selectedStaffUid,
                            );

                            Navigator.pop(
                              dialogContext,
                              staff,
                            );
                          },

                    child: const Text('Confirm Assignment'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || selectedStaff == null) return;

      // GET SELECTED STAFF DETAILS

      final staffData = selectedStaff.data();

      // The Firestore users document ID must be
      // the actual Firebase Authentication UID.
      final staffUid = selectedStaff.id;

      final storedUid =
          staffData['uid']?.toString();

      if (storedUid != null &&
          storedUid.isNotEmpty &&
          storedUid != staffUid) {
        _showMessage(
          'Staff profile UID does not match its document ID.',
          Colors.red,
        );
        return;
      }

      final staffName =
          staffData['name']?.toString() ?? 'Staff Member';

      // UPDATE FIRESTORE

      await _firestore
          .collection('complaints')
          .doc(complaintDocumentId)
          .update({
        'assignedStaffUid': staffUid,
        'assignedStaffName': staffName,
        'assignedAt': FieldValue.serverTimestamp(),

        // Assignment does NOT start the work.
        'status': 'Assigned',

        // Clear any previous acceptance/decline timestamps.
      
      });

      if (!mounted) return;

      _showMessage(
        'Complaint assigned to $staffName successfully.',
        Colors.green,
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'FIRESTORE ASSIGNMENT ERROR: ${e.code} - ${e.message}',
      );

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        e.code == 'permission-denied'
            ? 'Permission denied. Check coordinator role and Firestore rules.'
            : 'Assignment failed: ${e.message ?? e.code}',
        Colors.red,
      );
    } catch (e, stackTrace) {
      debugPrint('ASSIGNMENT ERROR: $e');

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        'Assignment failed: $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  // ==========================================
  // BADGE
  // ==========================================

  Widget _badge(String text, Color color) {
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
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // PRIORITY COLORS
  // ==========================================

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;

      case 'high':
        return Colors.deepOrange;

      case 'medium':
        return Colors.orange;

      case 'low':
        return green;

      default:
        return Colors.grey;
    }
  }

  // ==========================================
  // STATUS COLORS
  // ==========================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return green;

      case 'in progress':
        return blue;

      case 'assigned':
        return Colors.purple;

      case 'reported':
        return orange;

      default:
        return Colors.grey;
    }
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
