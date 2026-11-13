import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StaffComplaintDetailsPage extends StatefulWidget {
  final String complaintDocumentId;

  const StaffComplaintDetailsPage({
    super.key,
    required this.complaintDocumentId,
  });

  @override
  State<StaffComplaintDetailsPage> createState() =>
      _StaffComplaintDetailsPageState();
}

class _StaffComplaintDetailsPageState
    extends State<StaffComplaintDetailsPage> {

  static const Color navy = Color(0xFF092B65);
  static const Color blue = Color(0xFF075DD5);
  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF159957);
  static const Color red = Color(0xFFE84B3C);

  bool _isProcessing = false;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================
  // GET COMPLAINT DOCUMENT
  // ==========================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _complaintStream() {
    return _firestore
        .collection('complaints')
        .doc(widget.complaintDocumentId)
        .snapshots();
  }

  // ==========================================
  // ACCEPT COMPLAINT
  // ==========================================

  Future<void> _acceptComplaint(
    Map<String, dynamic> data,
  ) async {
    if (_isProcessing) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login again.', red);
      return;
    }

    final assignedStaffUid =
        data['assignedStaffUid']?.toString();

    if (assignedStaffUid != user.uid) {
      _showMessage(
        'This complaint is not assigned to your account.',
        red,
      );
      return;
    }

    final status =
        data['status']?.toString().toLowerCase();

    if (status != 'assigned') {
      _showMessage(
        'Only assigned complaints can be accepted.',
        orange,
      );
      return;
    }

    final confirm = await _showConfirmation(
      title: 'Accept Complaint',
      message:
          'Do you want to accept this complaint and start working on it?',
      confirmText: 'Accept',
      confirmColor: green,
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _firestore
          .collection('complaints')
          .doc(widget.complaintDocumentId)
          .update({
        'status': 'In Progress',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        'Complaint accepted successfully.',
        green,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to accept complaint: $e',
        red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================
  // DECLINE COMPLAINT
  // ==========================================

  Future<void> _declineComplaint(
    Map<String, dynamic> data,
  ) async {
    if (_isProcessing) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login again.', red);
      return;
    }

    if (data['assignedStaffUid'] != user.uid) {
      _showMessage(
        'This complaint is not assigned to your account.',
        red,
      );
      return;
    }

    if (data['status']?.toString() != 'Assigned') {
      _showMessage(
        'Only unaccepted complaints can be declined.',
        orange,
      );
      return;
    }

    final confirm = await _showConfirmation(
      title: 'Decline Complaint',
      message:
          'Are you sure you cannot handle this complaint? '
          'It will be returned to the coordinator for reassignment.',
      confirmText: 'Decline',
      confirmColor: red,
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _firestore
          .collection('complaints')
          .doc(widget.complaintDocumentId)
          .update({
        'status': 'Reported',
        'assignedStaffUid': null,
        'assignedStaffName': null,
        'assignedAt': null,
        'declinedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        'Complaint returned for reassignment.',
        green,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to decline complaint: $e',
        red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================
  // RESOLVE COMPLAINT
  // ==========================================

  Future<void> _resolveComplaint(
    Map<String, dynamic> data,
  ) async {
    if (_isProcessing) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login again.', red);
      return;
    }

    if (data['assignedStaffUid'] != user.uid) {
      _showMessage(
        'This complaint is not assigned to your account.',
        red,
      );
      return;
    }

    final currentStatus =
        data['status']?.toString().trim().toLowerCase();

    if (currentStatus != 'in progress') {
      _showMessage(
        'Only in-progress complaints can be resolved.',
        orange,
      );
      return;
    }

    final controller = TextEditingController();

    final resolution = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resolve Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe the work completed to resolve this issue.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Enter resolution details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) return;

                Navigator.pop(dialogContext, text);
              },
              child: const Text('Submit Resolution'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (resolution == null || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _firestore
          .collection('complaints')
          .doc(widget.complaintDocumentId)
          .update({
        'status': 'Resolved',
        'resolutionComment': resolution,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        'Complaint resolved successfully.',
        green,
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to resolve complaint: ${e.message ?? e.code}',
        red,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to resolve complaint: $e',
        red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================
  // CONFIRMATION DIALOG
  // ==========================================

  Future<bool?> _showConfirmation({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
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
  // INFORMATION ROW
  // ==========================================

  Widget _detailRow(
    String label,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value?.toString() ?? 'Not available',
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMATION SECTION
  // ==========================================

  Widget _informationCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Complaint Details',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _complaintStream(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load complaint.\n${snapshot.error}',
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

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Complaint not found.'),
            );
          }

          final data = snapshot.data!.data()!;

          final complaintId =
              data['complaintId']?.toString() ??
                  widget.complaintDocumentId;

          final title =
              data['title']?.toString() ?? 'Untitled';

          final category =
              data['category']?.toString() ?? 'General';

          final location =
              data['location']?.toString() ??
                  'Not specified';

          final description =
              data['description']?.toString() ??
                  'No description provided.';

          final studentName =
              data['studentName']?.toString() ??
                  'Unknown Student';

          final studentUSN =
              data['studentUSN']?.toString() ??
                  'Not available';

          final priority =
              data['priority']?.toString() ?? 'Medium';

          final status =
              data['status']?.toString() ?? 'Reported';

          final imageCount =
              data['imageCount'] ?? 0;

          final statusColor = _statusColor(status);
          final priorityColor =
              _priorityColor(priority);

          final isAssigned =
              status.toLowerCase() == 'assigned';

          final isInProgress =
              status.toLowerCase() == 'in progress';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // =================================
              // CURRENT STATUS CARD
              // =================================

              Container(
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.only(
                  bottom: 17,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      isInProgress
                          ? Icons.autorenew_rounded
                          : Icons.assignment_turned_in_rounded,
                      color: statusColor,
                      size: 53,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Current Status',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // =================================
              // COMPLAINT INFORMATION
              // =================================

              _informationCard(
                title: 'Complaint Information',
                children: [
                  _detailRow(
                    'Complaint ID',
                    complaintId,
                  ),
                  _detailRow(
                    'Issue Title',
                    title,
                  ),
                  _detailRow(
                    'Category',
                    category,
                  ),
                  _detailRow(
                    'Location',
                    location,
                  ),
                ],
              ),

              // =================================
              // DESCRIPTION
              // =================================

              _informationCard(
                title: 'Problem Description',
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              // =================================
              // STUDENT INFORMATION
              // =================================

              _informationCard(
                title: 'Reported By',
                children: [
                  _detailRow(
                    'Student Name',
                    studentName,
                  ),
                  _detailRow(
                    'Student USN',
                    studentUSN,
                  ),
                ],
              ),

              // =================================
              // ADDITIONAL INFORMATION
              // =================================

              _informationCard(
                title: 'Additional Information',
                children: [
                  Padding(
  padding: const EdgeInsets.symmetric(vertical: 9),
  child: Row(
    children: [
      const Expanded(
        flex: 4,
        child: Text(
          'Priority',
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 13,
          ),
        ),
      ),
      Expanded(
        flex: 6,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              priority,
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
                  _detailRow(
                    'Images Selected',
                    imageCount,
                  ),
                  _detailRow(
                    'Images Uploaded',
                    data['imagesUploaded'] == true
                        ? 'Yes'
                        : 'No',
                  ),
                ],
              ),

              // =================================
              // ACTION BUTTONS
              // =================================

              if (isAssigned) ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _acceptComplaint(data),
                    icon: const Icon(
                      Icons.check_circle_outline,
                    ),
                    label: Text(
                      _isProcessing
                          ? 'Please wait...'
                          : 'Accept Issue',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _declineComplaint(data),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blue,
                      side: const BorderSide(
                        color: blue,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              if (isInProgress)
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _resolveComplaint(data),
                    icon: const Icon(Icons.task_alt),
                    label: Text(
                      _isProcessing
                          ? 'Please wait...'
                          : 'Mark as Resolved',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              if (status.toLowerCase() == 'resolved')
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'This complaint has been resolved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
