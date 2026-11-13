import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CoordinatorComplaintsPage extends StatefulWidget {
  const CoordinatorComplaintsPage({super.key});

  @override
  State<CoordinatorComplaintsPage> createState() =>
      _CoordinatorComplaintsPageState();
}

class _CoordinatorComplaintsPageState
    extends State<CoordinatorComplaintsPage> {

  // ==========================================
  // VARIABLES
  // ==========================================

  String selectedStatus = 'All';
  String selectedPriority = 'All';

  bool _isAssigning = false;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final List<String> statuses = [
    'All',
    'Reported',
    'In Progress',
    'Resolved',
    'Closed',
  ];

  final List<String> priorities = [
    'All',
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  static const Color navy = Color(0xFF172554);
  static const Color blue = Color(0xFF075DD5);
  static const Color green = Color(0xFF159957);
  static const Color orange = Color(0xFFFF9800);


  // ==========================================
  // MAIN BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'Complaint Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          _buildFilters(),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('complaints')
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load complaints:\n${snapshot.error}',
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

                final documents =
                    snapshot.data?.docs ?? [];

                // FILTER COMPLAINTS

                final complaints = documents.where((doc) {
                  final data = doc.data();

                  final status =
                      data['status']?.toString() ?? 'Reported';

                  final priority =
                      data['priority']?.toString() ?? 'Medium';

                  final statusMatches =
                      selectedStatus == 'All' ||
                          status == selectedStatus;

                  final priorityMatches =
                      selectedPriority == 'All' ||
                          priority == selectedPriority;

                  return statusMatches && priorityMatches;
                }).toList();

                // SORT BY DATE

                complaints.sort((a, b) {
                  final aDate =
                      a.data()['createdAt'] as Timestamp?;

                  final bDate =
                      b.data()['createdAt'] as Timestamp?;

                  return (bDate?.millisecondsSinceEpoch ?? 0)
                      .compareTo(
                    aDate?.millisecondsSinceEpoch ?? 0,
                  );
                });

                if (complaints.isEmpty) {
                  return const Center(
                    child: Text(
                      'No complaints found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,

                  itemBuilder: (context, index) {
                    final document = complaints[index];

                    return _buildComplaintCard(
                      document.id,
                      document.data(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================
  // FILTER SECTION
  // ==========================================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            'Filter Complaints',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: _buildDropdown(
                  label: 'Status',
                  value: selectedStatus,
                  items: statuses,

                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedStatus = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildDropdown(
                  label: 'Priority',
                  value: selectedPriority,
                  items: priorities,

                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedPriority = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ==========================================
  // DROPDOWN
  // ==========================================

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,

      decoration: InputDecoration(
        labelText: label,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),

      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),

      onChanged: onChanged,
    );
  }


  // ==========================================
  // COMPLAINT CARD
  // ==========================================

  Widget _buildComplaintCard(
    String documentId,
    Map<String, dynamic> data,
  ) {

    final complaintId =
        data['complaintId']?.toString() ?? documentId;

    final title =
        data['title']?.toString() ?? 'Untitled Complaint';

    final category =
        data['category']?.toString() ?? 'Other';

    final location =
        data['location']?.toString() ?? 'Not specified';

    final studentName =
        data['studentName']?.toString() ?? 'Unknown Student';

    final status =
        data['status']?.toString() ?? 'Reported';

    final priority =
        data['priority']?.toString() ?? 'Medium';

    final assignedStaff =
        data['assignedStaffName']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: () {
          _showComplaintDetails(
            documentId,
            data,
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

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

                  _buildBadge(
                    priority,
                    _priorityColor(priority),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // TITLE

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text('Category: $category'),
              Text('Location: $location'),
              Text('Reported by: $studentName'),

              const SizedBox(height: 8),

              // ASSIGNED STAFF

              if (assignedStaff != null &&
                  assignedStaff.isNotEmpty)

                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: blue,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        'Assigned to: $assignedStaff',
                        style: const TextStyle(
                          color: blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                )

              else

                const Text(
                  'Not assigned yet',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 12),

              // STATUS

              Align(
                alignment: Alignment.centerRight,

                child: _buildBadge(
                  status,
                  _statusColor(status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==========================================
  // BADGE
  // ==========================================

  Widget _buildBadge(String text, Color color) {
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  // ==========================================
  // PRIORITY COLOR
  // ==========================================

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {

      case 'critical':
        return Colors.red;

      case 'high':
        return Colors.deepOrange;

      case 'medium':
        return Colors.orange;

      default:
        return Colors.green;
    }
  }


  // ==========================================
  // STATUS COLOR
  // ==========================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {

      case 'resolved':
      case 'closed':
        return green;

      case 'in progress':
        return blue;

      default:
        return orange;
    }
  }


  // ==========================================
  // COMPLAINT DETAILS
  // ==========================================

  void _showComplaintDetails(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final status = data['status']?.toString() ?? 'Reported';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            data['complaintId']?.toString() ?? documentId,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Title', data['title']),
                _detailRow('Category', data['category']),
                _detailRow('Description', data['description']),
                _detailRow('Location', data['location']),
                _detailRow('Student', data['studentName']),
                _detailRow('USN', data['studentUSN']),
                _detailRow('Priority', data['priority']),
                _detailRow('Status', status),
                _detailRow('Assigned Staff', data['assignedStaffName']),
                if (status == 'Resolved' || status == 'Closed') ...[
                  const Divider(height: 24),
                  const Text(
                    'Staff Resolution',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Resolution Comment',
                    data['resolutionComment'],
                  ),
                  _detailRow(
                    'Resolved At',
                    _formatTimestamp(data['resolvedAt']),
                  ),
                ],
                if (status == 'Closed')
                  _detailRow(
                    'Verified At',
                    _formatTimestamp(data['verifiedAt']),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            if (status == 'Resolved') ...[
              TextButton.icon(
                onPressed: _isAssigning
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _reopenComplaint(documentId);
                      },
                icon: const Icon(Icons.refresh, color: orange),
                label: const Text(
                  'Reopen',
                  style: TextStyle(color: orange),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isAssigning
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _approveResolution(documentId);
                      },
                icon: const Icon(Icons.verified),
                label: const Text('Approve & Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else if (status == 'Reported' || status == 'Assigned')
              ElevatedButton.icon(
                onPressed: _isAssigning
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _assignComplaint(documentId, data);
                      },
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(
                  data['assignedStaffUid'] == null
                      ? 'Assign Staff'
                      : 'Reassign Staff',
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return 'Not available';
    final date = value.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _approveResolution(String documentId) async {
    if (_isAssigning) return;
    setState(() => _isAssigning = true);

    try {
      await _firestore.collection('complaints').doc(documentId).update({
        'status': 'Closed',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showMessage('Resolution approved. Complaint closed.', green);
    } on FirebaseException catch (e) {
      debugPrint('APPROVE RESOLUTION ERROR: ${e.code} - ${e.message}');
      if (!mounted) return;
      _showMessage('Unable to approve resolution: ${e.message}', Colors.red);
    } catch (e, stackTrace) {
      debugPrint('APPROVE RESOLUTION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showMessage('Unable to approve resolution: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  Future<void> _reopenComplaint(String documentId) async {
    if (_isAssigning) return;
    setState(() => _isAssigning = true);

    try {
      await _firestore.collection('complaints').doc(documentId).update({
        'status': 'In Progress',
        'reopenedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showMessage(
        'Complaint reopened and returned to In Progress.',
        orange,
      );
    } on FirebaseException catch (e) {
      debugPrint('REOPEN COMPLAINT ERROR: ${e.code} - ${e.message}');
      if (!mounted) return;
      _showMessage('Unable to reopen complaint: ${e.message}', Colors.red);
    } catch (e, stackTrace) {
      debugPrint('REOPEN COMPLAINT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showMessage('Unable to reopen complaint: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }


  // ==========================================
  // ASSIGN COMPLAINT TO STAFF
  // ==========================================

  Future<void> _assignComplaint(
    String complaintDocumentId,
    Map<String, dynamic> complaintData,
  ) async {

    if (_isAssigning) return;

    try {

      setState(() {
        _isAssigning = true;
      });

      // STEP 1: LOAD STAFF ACCOUNTS

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

      // STEP 2: SHOW STAFF SELECTION DIALOG

      String? selectedStaffUid =
          complaintData['assignedStaffUid']?.toString();

      final selectedStaff =
          await showDialog<
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
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Select a staff member to handle this complaint.',
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

                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || selectedStaff == null) return;

      // STEP 3: GET STAFF INFORMATION

      final staffData = selectedStaff.data();

      final staffUid = selectedStaff.id;

      final staffName =
          staffData['name']?.toString() ?? 'Staff Member';

      // STEP 4: UPDATE COMPLAINT IN FIRESTORE

      await _firestore
          .collection('complaints')
          .doc(complaintDocumentId)
          .update({

        'assignedStaffUid': staffUid,

        'assignedStaffName': staffName,

        'assignedAt': FieldValue.serverTimestamp(),

        'status': 'Assigned',
      });

      // STEP 5: SHOW SUCCESS MESSAGE

      if (!mounted) return;

      _showMessage(
        'Complaint successfully assigned to $staffName.',
        Colors.green,
      );

    } catch (e, stackTrace) {

      debugPrint(
        'COMPLAINT ASSIGNMENT ERROR: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        'Unable to assign complaint: $e',
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
  // DETAIL ROW
  // ==========================================

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Text(
        '$label: ${value ?? 'Not available'}',

        style: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }


  // ==========================================
  // SHOW MESSAGE
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