import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CoordinatorStaffManagementPage extends StatefulWidget {
  const CoordinatorStaffManagementPage({super.key});

  @override
  State<CoordinatorStaffManagementPage> createState() =>
      _CoordinatorStaffManagementPageState();
}

class _CoordinatorStaffManagementPageState
    extends State<CoordinatorStaffManagementPage> {
  static const Color navy = Color(0xFF09213F);
  static const Color blue = Color(0xFF075DD5);
  static const Color background = Color(0xFFF4F7FC);
  static const Color green = Color(0xFF00A879);
  static const Color orange = Color(0xFFFFB52E);
  static const Color red = Color(0xFFE74C3C);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String selectedDepartment = 'All Departments';

  final List<String> departments = [
    'All Departments',
    'Electrical',
    'Plumbing',
    'Furniture',
    'Infrastructure',
    'IT & Network',
    'Cleanliness',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Staff Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: 'staff')
            .snapshots(),
        builder: (context, staffSnapshot) {
          if (staffSnapshot.hasError) {
            return _errorView(
              'Unable to load staff:\n${staffSnapshot.error}',
            );
          }

          if (staffSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final staffDocuments =
              staffSnapshot.data?.docs ?? [];

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('complaints')
                .snapshots(),
            builder: (context, complaintSnapshot) {
              if (complaintSnapshot.hasError) {
                return _errorView(
                  'Unable to load complaint statistics:\n'
                  '${complaintSnapshot.error}',
                );
              }

              if (complaintSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final complaintDocuments =
                  complaintSnapshot.data?.docs ?? [];

              final complaints = complaintDocuments
                  .map((doc) => doc.data())
                  .toList();

              final staff = staffDocuments.map((doc) {
                return {
                  ...doc.data(),
                  'uid': doc.id,
                };
              }).toList();

              final totalAssigned = complaints.where((item) {
                final uid = item['assignedStaffUid'];
                return uid != null &&
                    uid.toString().isNotEmpty;
              }).length;

              final totalResolved = complaints.where((item) {
                final uid = item['assignedStaffUid'];
                return uid != null &&
                    uid.toString().isNotEmpty &&
                    _status(item) == 'Resolved';
              }).length;

              final filteredStaff = staff.where((member) {
                final name =
                    member['name']?.toString().toLowerCase() ?? '';

                final email =
                    member['email']?.toString().toLowerCase() ?? '';

                final department =
                    member['department']?.toString() ?? '';

                final search =
                    _searchController.text.trim().toLowerCase();

                final matchesSearch =
                    search.isEmpty ||
                    name.contains(search) ||
                    email.contains(search);

                final matchesDepartment =
                    selectedDepartment == 'All Departments' ||
                    department == selectedDepartment;

                return matchesSearch && matchesDepartment;
              }).toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await _firestore
                      .collection('users')
                      .where('role', isEqualTo: 'staff')
                      .get(
                        const GetOptions(
                          source: Source.server,
                        ),
                      );

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
                    _welcomeBanner(),

                    const SizedBox(height: 20),

                    const Text(
                      'Staff Overview',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _overviewCards(
                      staff.length,
                      totalAssigned,
                      totalResolved,
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Maintenance Staff',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _searchAndFilter(),

                    const SizedBox(height: 16),

                    if (filteredStaff.isEmpty)
                      _emptyView()
                    else
                      ...filteredStaff.map((member) {
                        final uid = member['uid'].toString();

                        final assigned = complaints.where((item) {
                          return item['assignedStaffUid']
                                  ?.toString() ==
                              uid;
                        }).toList();

                        final resolved = assigned.where((item) {
                          return _status(item) == 'Resolved';
                        }).length;

                        final inProgress = assigned.where((item) {
                          return _status(item) == 'In Progress';
                        }).length;

                        final pending = assigned.where((item) {
                          return _status(item) == 'Reported';
                        }).length;

                        return _staffCard(
                          member,
                          assigned.length,
                          resolved,
                          inProgress,
                          pending,
                        );
                      }),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================
  // WELCOME BANNER
  // ==========================================

  Widget _welcomeBanner() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.engineering_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'Staff Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Monitor maintenance staff, track workloads '
            'and review complaint resolution performance.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OVERVIEW CARDS
  // ==========================================

  Widget _overviewCards(
    int totalStaff,
    int assigned,
    int resolved,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _statCard(
              'Total Staff',
              totalStaff.toString(),
              Icons.people_alt_rounded,
              blue,
            ),
            _statCard(
              'Assigned Complaints',
              assigned.toString(),
              Icons.assignment_rounded,
              orange,
            ),
            _statCard(
              'Resolved Complaints',
              resolved.toString(),
              Icons.task_alt_rounded,
              green,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEDF0F5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
                    fontSize: 10,
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
  // SEARCH AND FILTER
  // ==========================================

  Widget _searchAndFilter() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Search staff by name or email',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedDepartment,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Filter by Department',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: departments.map((department) {
            return DropdownMenuItem<String>(
              value: department,
              child: Text(department),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedDepartment = value;
            });
          },
        ),
      ],
    );
  }

  // ==========================================
  // STAFF CARD
  // ==========================================

  Widget _staffCard(
    Map<String, dynamic> member,
    int assigned,
    int resolved,
    int inProgress,
    int pending,
  ) {
    final name = member['name']?.toString() ?? 'Unknown Staff';
    final email = member['email']?.toString() ?? 'No email';
    final department =
        member['department']?.toString() ?? 'Not specified';

    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _showStaffDetails(
            name,
            email,
            department,
            assigned,
            resolved,
            inProgress,
            pending,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFFE6EEFF),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: blue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  department,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Divider(height: 1),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: _workloadItem(
                      'Assigned',
                      assigned,
                      blue,
                    ),
                  ),
                  Expanded(
                    child: _workloadItem(
                      'In Progress',
                      inProgress,
                      orange,
                    ),
                  ),
                  Expanded(
                    child: _workloadItem(
                      'Resolved',
                      resolved,
                      green,
                    ),
                  ),
                ],
              ),

              if (pending > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '$pending reported complaint(s) awaiting action',
                  style: const TextStyle(
                    color: red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _workloadItem(
    String title,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STAFF DETAILS
  // ==========================================

  void _showStaffDetails(
    String name,
    String email,
    String department,
    int assigned,
    int resolved,
    int inProgress,
    int pending,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Email', email),
                _detailRow('Department', department),
                _detailRow('Assigned Complaints', '$assigned'),
                _detailRow('In Progress', '$inProgress'),
                _detailRow('Resolved', '$resolved'),
                _detailRow('Reported / Pending', '$pending'),
              ],
            ),
          ),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  String _status(Map<String, dynamic> item) {
    return item['status']?.toString() ?? 'Reported';
  }

  Widget _emptyView() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 45,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No staff members found.',
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}