import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class CoordinatorReportsPage extends StatefulWidget {
  const CoordinatorReportsPage({super.key});

  @override
  State<CoordinatorReportsPage> createState() =>
      _CoordinatorReportsPageState();
      
}

class _CoordinatorReportsPageState
    extends State<CoordinatorReportsPage> {
  static const Color navy = Color(0xFF09213F);
  static const Color blue = Color(0xFF075DD5);
  static const Color background = Color(0xFFF4F7FC);
  static const Color green = Color(0xFF00A879);
  static const Color orange = Color(0xFFFFB52E);
  static const Color red = Color(0xFFE74C3C);
  static const Color purple = Color(0xFF7952B6);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String selectedPeriod = 'Last 30 Days';
  String selectedDepartment = 'All Departments';

  final List<String> periods = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'All Time',
  ];

  final List<String> departments = [
    'All Departments',
    'Electrical',
    'Plumbing',
    'Furniture',
    'Infrastructure',
    'IT & Network',
    'Cleanliness',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Reports Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('complaints')
            .snapshots(),

        builder: (context, complaintSnapshot) {
          if (complaintSnapshot.hasError) {
            return _errorView(
              'Unable to load complaint reports:\n'
              '${complaintSnapshot.error}',
            );
          }

          if (complaintSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allComplaints =
              complaintSnapshot.data?.docs ?? [];

          final filteredComplaints = allComplaints.where((doc) {
            return _matchesFilters(doc.data());
          }).toList();

          final records = filteredComplaints
              .map((doc) => doc.data())
              .toList();

          final total = records.length;

          final reported = records.where((item) {
            return _status(item) == 'Reported';
          }).length;

          final inProgress = records.where((item) {
            return _status(item) == 'In Progress';
          }).length;

          final resolved = records.where((item) {
            return _status(item) == 'Resolved';
          }).length;

          final critical = records.where((item) {
            return _priority(item) == 'Critical';
          }).length;

          final high = records.where((item) {
            return _priority(item) == 'High';
          }).length;

          final departmentCounts =
              _departmentCounts(records);

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('users')
                .where('role', isEqualTo: 'staff')
                .snapshots(),

            builder: (context, staffSnapshot) {
              if (staffSnapshot.hasError) {
                return _errorView(
                  'Unable to load staff reports:\n'
                  '${staffSnapshot.error}',
                );
              }

              if (staffSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final staff = staffSnapshot.data?.docs ?? [];

              final averageResolution =
                  _averageResolution(records);

              return RefreshIndicator(
                onRefresh: _refreshData,

                child: ListView(
                  padding: const EdgeInsets.all(16),

                  children: [
                    _welcomeBanner(),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      'Report Filters',
                      'Choose a reporting period and department.',
                    ),

                    const SizedBox(height: 12),

                    _filterSection(),

                    const SizedBox(height: 22),

                    _sectionTitle(
                      'Complaint Summary',
                      'Overview of complaints in the selected period.',
                    ),

                    const SizedBox(height: 12),

                    _summaryGrid(
                      total,
                      resolved,
                      inProgress,
                      reported,
                    ),

                    const SizedBox(height: 22),

                    _resolutionSummary(
                      total,
                      resolved,
                      averageResolution,
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle(
                      'Priority Report',
                      'Complaints grouped by urgency.',
                    ),

                    const SizedBox(height: 12),

                    _priorityReport(
                      records,
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle(
                      'Department Report',
                      'Complaint distribution across departments.',
                    ),

                    const SizedBox(height: 12),

                    _departmentReport(
                      departmentCounts,
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle(
                      'Staff Performance',
                      'Assigned and resolved complaints per staff member.',
                    ),

                    const SizedBox(height: 12),

                   _staffPerformance(
  staff,
  records,
),

const SizedBox(height: 22),

_exportButtons(
  records,
  total,
  resolved,
  inProgress,
  reported,
  staff,
),

const SizedBox(height: 22),

_reportFooter(
  total,
  critical,
  high,
),

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
// EXPORT BUTTONS
// ==========================================

Widget _exportButtons(
  List<Map<String, dynamic>> records,
  int total,
  int resolved,
  int inProgress,
  int reported,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> staff,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Export Reports',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Download or share your filtered complaint reports.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _exportPdf(
              records,
              total,
              resolved,
              inProgress,
              reported,
              staff,
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _exportCsv(records),
            icon: const Icon(Icons.table_chart),
            label: const Text('Export CSV Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
// ==========================================
// PDF EXPORT
// ==========================================

Future<void> _exportPdf(
  List<Map<String, dynamic>> records,
  int total,
  int resolved,
  int inProgress,
  int reported,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> staff,
) async {
  try {
    final pdf = pw.Document();

    final staffRows = <List<String>>[];

    for (final document in staff) {
      final member = document.data();
      final uid = document.id;

      final assigned = records.where((item) {
        return item['assignedStaffUid']?.toString() == uid;
      }).toList();

      final staffResolved = assigned.where((item) {
        return _status(item) == 'Resolved';
      }).length;

      staffRows.add([
        member['name']?.toString() ?? 'Unknown',
        member['department']?.toString() ?? 'Other',
        assigned.length.toString(),
        staffResolved.toString(),
      ]);
    }

    final complaintRows = records.map((item) {
      return [
        item['complaintId']?.toString() ?? 'N/A',
        item['title']?.toString() ?? 'Untitled',
        item['category']?.toString() ?? 'Other',
        _priority(item),
        _status(item),
        item['studentName']?.toString() ?? 'Unknown',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),

        build: (context) => [
          pw.Text(
            'CAMPUSFIX',
            style: pw.TextStyle(
              fontSize: 25,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            'Campus Complaint Management Report',
            style: const pw.TextStyle(fontSize: 16),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            'Generated: ${DateTime.now()}',
          ),

          pw.Text('Period: $selectedPeriod'),

          pw.Text('Department: $selectedDepartment'),

          pw.Divider(),

          pw.SizedBox(height: 12),

          pw.Text(
            'Complaint Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              'Total',
              'Resolved',
              'In Progress',
              'Reported',
            ],
            data: [
              [
                total.toString(),
                resolved.toString(),
                inProgress.toString(),
                reported.toString(),
              ],
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Complaint Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              'Complaint ID',
              'Title',
              'Category',
              'Priority',
              'Status',
              'Student',
            ],
            data: complaintRows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 7,
            ),
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Staff Performance',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              'Staff Name',
              'Department',
              'Assigned',
              'Resolved',
            ],
            data: staffRows,
          ),

          pw.SizedBox(height: 25),

          pw.Divider(),

          pw.Text(
            'Generated by CampusFix Coordinator Panel',
            style: const pw.TextStyle(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'CampusFix_Complaint_Report.pdf',
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF export failed: $e'),
        backgroundColor: red,
      ),
    );
  }
}
// ==========================================
// CSV EXPORT
// ==========================================

Future<void> _exportCsv(
  List<Map<String, dynamic>> records,
) async {
  try {
    final rows = <List<String>>[
      [
        'Complaint ID',
        'Title',
        'Category',
        'Description',
        'Location',
        'Student Name',
        'Student USN',
        'Priority',
        'Status',
        'Assigned Staff UID',
        'Created Date',
      ],
    ];

    for (final item in records) {
      final createdAt = item['createdAt'];

      String createdDate = '';

      if (createdAt is Timestamp) {
        createdDate = createdAt.toDate().toString();
      }

      rows.add([
        item['complaintId']?.toString() ?? '',
        item['title']?.toString() ?? '',
        item['category']?.toString() ?? '',
        item['description']?.toString() ?? '',
        item['location']?.toString() ?? '',
        item['studentName']?.toString() ?? '',
        item['studentUSN']?.toString() ?? '',
        _priority(item),
        _status(item),
        item['assignedStaffUid']?.toString() ?? '',
        createdDate,
      ]);
    }

    String escapeCsv(String value) {
      return '"${value.replaceAll('"', '""')}"';
    }

    final csv = rows.map((row) {
      return row.map(escapeCsv).join(',');
    }).join('\r\n');

    final csvBytes = utf8.encode('\uFEFF$csv');

    await SharePlus.instance.share(
      ShareParams(
        title: 'CampusFix Complaint Report',
        subject: 'CampusFix Complaint Report',
        text: 'CampusFix complaint report - $selectedPeriod',
        files: [
          XFile.fromData(
            csvBytes,
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: [
          'CampusFix_Complaint_Report.csv',
        ],
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV export failed: $e'),
        backgroundColor: red,
      ),
    );
  }
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
            Icons.description_rounded,
            color: Colors.white,
            size: 34,
          ),

          SizedBox(height: 12),

          Text(
            'CampusFix Reports',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Generate and review campus complaint reports, '
            'department performance and maintenance staff activity.',
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
  // SECTION TITLE
  // ==========================================

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FILTER SECTION
  // ==========================================

  Widget _filterSection() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Column(
        children: [
          _filterDropdown(
            'Reporting Period',
            selectedPeriod,
            periods,
            (value) {
              if (value == null) return;

              setState(() {
                selectedPeriod = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _filterDropdown(
            'Department',
            selectedDepartment,
            departments,
            (value) {
              if (value == null) return;

              setState(() {
                selectedDepartment = value;
              });
            },
          ),
        ],
      ),
    );
  }

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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
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
  // FILTER LOGIC
  // ==========================================

  bool _matchesFilters(
    Map<String, dynamic> item,
  ) {
    final createdAt = item['createdAt'];

    if (selectedPeriod != 'All Time') {
      if (createdAt is! Timestamp) return false;

      final now = DateTime.now();
      final createdDate = createdAt.toDate();

      DateTime startDate;

      switch (selectedPeriod) {
        case 'Today':
          startDate = DateTime(
            now.year,
            now.month,
            now.day,
          );
          break;

        case 'Last 7 Days':
          startDate = now.subtract(
            const Duration(days: 7),
          );
          break;

        case 'Last 30 Days':
          startDate = now.subtract(
            const Duration(days: 30),
          );
          break;

        case 'Last 90 Days':
          startDate = now.subtract(
            const Duration(days: 90),
          );
          break;

        default:
          startDate = DateTime(2000);
      }

      if (createdDate.isBefore(startDate)) {
        return false;
      }
    }

    if (selectedDepartment != 'All Departments') {
      final category =
          item['category']?.toString() ?? '';

      final department =
          _departmentForCategory(category);

      if (department != selectedDepartment) {
        return false;
      }
    }

    return true;
  }

  // ==========================================
  // SUMMARY GRID
  // ==========================================

  Widget _summaryGrid(
    int total,
    int resolved,
    int inProgress,
    int reported,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,

      children: [
        _summaryCard(
          'Total Complaints',
          total.toString(),
          Icons.assignment_rounded,
          blue,
        ),

        _summaryCard(
          'Resolved',
          resolved.toString(),
          Icons.task_alt_rounded,
          green,
        ),

        _summaryCard(
          'In Progress',
          inProgress.toString(),
          Icons.autorenew_rounded,
          purple,
        ),

        _summaryCard(
          'Reported / Pending',
          reported.toString(),
          Icons.pending_actions_rounded,
          orange,
        ),
      ],
    );
  }

  Widget _summaryCard(
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
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
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
  // RESOLUTION SUMMARY
  // ==========================================

  Widget _resolutionSummary(
    int total,
    int resolved,
    Duration? average,
  ) {
    final percentage = total == 0
        ? 0.0
        : resolved / total * 100;

    final averageText = average == null
        ? 'Not available'
        : average.inDays >= 1
            ? '${average.inDays} days'
            : '${average.inHours} hours';

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Resolution Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resolution Rate',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                ),
              ),

              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(green),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Average Resolution Time',
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            averageText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRIORITY REPORT
  // ==========================================

  Widget _priorityReport(
    List<Map<String, dynamic>> records,
  ) {
    final priorities = {
      'Critical': 0,
      'High': 0,
      'Medium': 0,
      'Low': 0,
    };

    for (final item in records) {
      final priority = _priority(item);

      if (priorities.containsKey(priority)) {
        priorities[priority] =
            priorities[priority]! + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Column(
        children: [
          _priorityRow(
            'Critical',
            priorities['Critical']!,
            red,
          ),

          _priorityRow(
            'High',
            priorities['High']!,
            Colors.deepOrange,
          ),

          _priorityRow(
            'Medium',
            priorities['Medium']!,
            orange,
          ),

          _priorityRow(
            'Low',
            priorities['Low']!,
            green,
          ),
        ],
      ),
    );
  }

  Widget _priorityRow(
    String title,
    int count,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DEPARTMENT REPORT
  // ==========================================

  Map<String, int> _departmentCounts(
    List<Map<String, dynamic>> records,
  ) {
    final counts = <String, int>{};

    for (final item in records) {
      final department = _departmentForCategory(
        item['category']?.toString() ?? '',
      );

      counts[department] = (counts[department] ?? 0) + 1;
    }

    return counts;
  }

  Widget _departmentReport(
    Map<String, int> counts,
  ) {
    if (counts.isEmpty) {
      return _emptyCard('No department reports available.');
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: DataTable(
          columns: const [
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Complaints')),
          ],

          rows: entries.map((entry) {
            return DataRow(
              cells: [
                DataCell(Text(entry.key)),
                DataCell(
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // STAFF PERFORMANCE
  // ==========================================

  Widget _staffPerformance(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> staff,
    List<Map<String, dynamic>> complaints,
  ) {
    if (staff.isEmpty) {
      return _emptyCard('No maintenance staff found.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: DataTable(
          columns: const [
            DataColumn(label: Text('Staff')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Assigned')),
            DataColumn(label: Text('Resolved')),
          ],

          rows: staff.map((document) {
            final member = document.data();

            final uid = document.id;

            final assigned = complaints.where((item) {
              return item['assignedStaffUid']?.toString() == uid;
            }).toList();

            final resolved = assigned.where((item) {
              return _status(item) == 'Resolved';
            }).length;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    member['name']?.toString() ?? 'Unknown',
                  ),
                ),

                DataCell(
                  Text(
                    member['department']?.toString() ?? 'Other',
                  ),
                ),

                DataCell(
                  Text(assigned.length.toString()),
                ),

                DataCell(
                  Text(
                    resolved.toString(),
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // REPORT FOOTER
  // ==========================================

  Widget _reportFooter(
    int total,
    int critical,
    int high,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Report Summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Total complaints: $total',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          Text(
            'Critical priority: $critical',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          Text(
            'High priority: $high',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DEPARTMENT MAPPING
  // ==========================================

  String _departmentForCategory(String category) {
    final value = category.toLowerCase();

    if (value.contains('electrical')) {
      return 'Electrical';
    }

    if (value.contains('plumbing')) {
      return 'Plumbing';
    }

    if (value.contains('furniture')) {
      return 'Furniture';
    }

    if (value.contains('infrastructure')) {
      return 'Infrastructure';
    }

    if (value.contains('it') ||
        value.contains('network') ||
        value.contains('wifi')) {
      return 'IT & Network';
    }

    if (value.contains('clean')) {
      return 'Cleanliness';
    }

    return 'Other';
  }

  // ==========================================
  // STATUS AND PRIORITY
  // ==========================================

  String _status(Map<String, dynamic> item) {
    return item['status']?.toString() ?? 'Reported';
  }

  String _priority(Map<String, dynamic> item) {
    return item['priority']?.toString() ?? 'Medium';
  }

  // ==========================================
  // AVERAGE RESOLUTION TIME
  // ==========================================

  Duration? _averageResolution(
    List<Map<String, dynamic>> records,
  ) {
    var totalMilliseconds = 0;
    var count = 0;

    for (final item in records) {
      if (_status(item) != 'Resolved') continue;

      final created = item['createdAt'];
      final resolved = item['resolvedAt'];

      if (created is! Timestamp ||
          resolved is! Timestamp) {
        continue;
      }

      final difference = resolved
          .toDate()
          .difference(created.toDate());

      if (difference.isNegative) continue;

      totalMilliseconds += difference.inMilliseconds;
      count++;
    }

    if (count == 0) return null;

    return Duration(
      milliseconds: totalMilliseconds ~/ count,
    );
  }

  // ==========================================
  // REFRESH
  // ==========================================

  Future<void> _refreshData() async {
    await _firestore
        .collection('complaints')
        .get(
          const GetOptions(source: Source.server),
        );

    await _firestore
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .get(
          const GetOptions(source: Source.server),
        );
  }

  // ==========================================
  // EMPTY AND ERROR VIEWS
  // ==========================================

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.blueGrey,
          ),
        ),
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