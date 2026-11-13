import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'coordinator_complaints_page.dart';
import '../../services/auth_service.dart';
import 'coordinator_assignments_page.dart';
import 'coordinator_analytics_page.dart';
import 'coordinator_staff_management_page.dart';
import 'coordinator_reports_page.dart';
import 'coordinator_settings_page.dart';
class CoordinatorDashboardPage extends StatefulWidget {
  const CoordinatorDashboardPage({super.key});

  @override
  State<CoordinatorDashboardPage> createState() =>
      _CoordinatorDashboardPageState();
}

class _CoordinatorDashboardPageState
    extends State<CoordinatorDashboardPage> {
  static const Color navy = Color(0xFF102B50);
  static const Color blue = Color(0xFF1769D2);
  static const Color background = Color(0xFFF3F6FB);

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      drawer: _navigationDrawer(context),

      // TOP APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: navy),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: blue,
              ),
            ),
            const SizedBox(width: 9),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAMPUSFIX',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _message(
              context,
              'Admin notifications will be implemented next.',
            ),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: navy,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 13),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE8F0FF),
              child: Icon(
                Icons.person_rounded,
                color: blue,
                size: 19,
              ),
            ),
          ),
        ],
      ),

      // LIVE FIRESTORE DASHBOARD
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorView(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: blue),
            );
          }

          final complaints =
              snapshot.data?.docs.map((doc) => doc.data()).toList() ??
                  <Map<String, dynamic>>[];

          final total = complaints.length;

          final resolved = complaints
    .where((c) {
      final status = _status(c);
      return status == 'resolved' || status == 'closed';
    })
    .length;

          final inProgress = complaints
              .where((c) => _status(c) == 'in progress')
              .length;

          final pending = complaints
              .where((c) => _status(c) == 'reported')
              .length;

          return RefreshIndicator(
            color: blue,
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('complaints')
                  .get(
                    const GetOptions(source: Source.server),
                  );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 22),
              children: [
                _welcomeBanner(),

                const SizedBox(height: 17),

                _sectionTitle('Dashboard', 'Last 7 Days'),

                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  childAspectRatio: 1.62,
                  children: [
                    _statCard(
                      'Total Complaints',
                      total,
                      Icons.assignment_rounded,
                      const Color(0xFF2878E5),
                      const Color(0xFFEAF2FF),
                    ),
                    _statCard(
                      'Resolved',
                      resolved,
                      Icons.check_circle_rounded,
                      const Color(0xFF0FA66A),
                      const Color(0xFFE7F7EF),
                    ),
                    _statCard(
                      'In Progress',
                      inProgress,
                      Icons.pending_actions_rounded,
                      const Color(0xFFF0A000),
                      const Color(0xFFFFF4DE),
                    ),
                    _statCard(
                      'Pending',
                      pending,
                      Icons.warning_rounded,
                      const Color(0xFFE64B55),
                      const Color(0xFFFFECEE),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _sectionTitle(
                  'Complaints Trend',
                  'Last 7 Days',
                ),

                const SizedBox(height: 9),

                _trendCard(_sevenDayCounts(complaints)),

                const SizedBox(height: 18),

                _sectionTitle(
                  'Complaints by Department',
                  'All time',
                ),

                const SizedBox(height: 9),

                _departmentGrid(
                  _departmentCounts(complaints),
                  total,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
    // ADMIN NAVIGATION DRAWER
  Widget _navigationDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF09213F),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 22),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.apartment_rounded,
                      color: blue,
                      size: 29,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'CAMPUSFIX',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24),

            _drawerItem(
              context,
              Icons.dashboard_rounded,
              'Dashboard',
              true,
            ),

            _drawerItem(
              context,
              Icons.people_alt_rounded,
              'Users',
              false,
            ),

           Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 2,
  ),
  child: ListTile(
    dense: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
    ),
    leading: const Icon(
      Icons.assignment_rounded,
      color: Colors.white70,
      size: 20,
    ),
    title: const Text(
      'Complaints',
      style: TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: () {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const CoordinatorComplaintsPage(),
        ),
      );
    },
  ),
),

            _drawerItem(
              context,
              Icons.assignment_ind_rounded,
              'Assignments',
              false,
            ),

            _drawerItem(
              context,
              Icons.analytics_rounded,
              'Analytics',
              false,
            ),

            _drawerItem(
              context,
              Icons.description_rounded,
              'Reports',
              false,
            ),

            _drawerItem(
              context,
              Icons.settings_rounded,
              'Settings',
              false,
            ),

            const Spacer(),

            const Divider(color: Colors.white24),

            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.white70,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _authService.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // DRAWER MENU ITEMS
Widget _drawerItem(
  BuildContext context,
  IconData icon,
  String title,
  bool selected,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 2,
    ),
    child: ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
      ),
      leading: Icon(
        icon,
        color: selected ? Colors.white : Colors.white70,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontSize: 13,
          fontWeight:
              selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
     onTap: () {
  Navigator.pop(context);

  if (title == 'Assignments') {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            const CoordinatorAssignmentsPage(),
      ),
    );
  } else if (title == 'Analytics') {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            const CoordinatorAnalyticsPage(),
      ),
    );
    } else if (title == 'Settings') {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const CoordinatorSettingsPage(),
    ),
  );
  } else if (title == 'Users') {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          const CoordinatorStaffManagementPage(),
    ),
  );
  } else if (title == 'Reports') {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const CoordinatorReportsPage(),
    ),
  );
  }
   else if (!selected) {
    _message(
      context,
      '$title screen will be connected in the next stage.',
    );
  }
},
    ),
  );
}

  // ADMIN WELCOME BANNER
  Widget _welcomeBanner() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _authService.getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();

        final name = _text(profile?['name']).isEmpty
            ? 'Administrator'
            : _text(profile?['name']);

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF10366E),
                Color(0xFF176FC6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADMINISTRATOR',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Manage • Monitor • Improve',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // SECTION TITLE
  Widget _sectionTitle(String title, String trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        Text(
          trailing,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // DASHBOARD STATISTICS CARD
  Widget _statCard(
    String title,
    int value,
    IconData icon,
    Color color,
    Color tint,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.045),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),

              const Spacer(),

              Icon(
                Icons.trending_up_rounded,
                color: color.withValues(alpha: 0.65),
                size: 16,
              ),
            ],
          ),

          const Spacer(),

          Text(
            '$value',
            style: const TextStyle(
              color: navy,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // COMPLAINT TREND CHART CARD
  Widget _trendCard(List<int> values) {
    final labels = _dayLabels();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        13,
        11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.045),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Complaints received',
                style: TextStyle(
                  color: navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Spacer(),

              Icon(
                Icons.show_chart_rounded,
                color: blue,
                size: 18,
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(values),
            ),
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 9,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }  // DEPARTMENT STATISTICS GRID
  Widget _departmentGrid(
    Map<String, int> counts,
    int total,
  ) {
    const departments = [
      _Department(
        'Electrical',
        Icons.bolt_rounded,
        Color(0xFFFFB000),
        Color(0xFFFFF4DA),
      ),
      _Department(
        'Plumbing',
        Icons.water_drop_rounded,
        Color(0xFF1684D8),
        Color(0xFFE7F3FF),
      ),
      _Department(
        'Furniture',
        Icons.chair_alt_rounded,
        Color(0xFFF07832),
        Color(0xFFFFEFE5),
      ),
      _Department(
        'Infrastructure',
        Icons.apartment_rounded,
        Color(0xFF16A36A),
        Color(0xFFE7F7EF),
      ),
      _Department(
        'IT & Network',
        Icons.wifi_rounded,
        Color(0xFF8054D6),
        Color(0xFFF1EBFF),
      ),
      _Department(
        'Cleanliness',
        Icons.cleaning_services_rounded,
        Color(0xFFE14C91),
        Color(0xFFFFECF5),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: departments.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 2.55,
      ),
      itemBuilder: (context, index) {
        final department = departments[index];
        final count = counts[department.name] ?? 0;

        final percent = total == 0
            ? 0
            : (count * 100 / total).round();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: navy.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: department.tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  department.icon,
                  color: department.color,
                  size: 17,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),

                    Text(
                      department.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '$percent%',
                style: TextStyle(
                  color: department.color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ERROR VIEW
  Widget _errorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 40,
            ),

            const SizedBox(height: 10),

            const Text(
              'Unable to load complaints',
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONVERT VALUE TO STRING
  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  // GET COMPLAINT STATUS
  String _status(Map<String, dynamic> complaint) {
    return _text(complaint['status']).toLowerCase();
  }

  // LAST SEVEN DAYS COMPLAINT COUNTS
  List<int> _sevenDayCounts(
    List<Map<String, dynamic>> complaints,
  ) {
    final now = DateTime.now();

    final firstDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final counts = List<int>.filled(7, 0);

    for (final complaint in complaints) {
      final createdAt = complaint['createdAt'];

      if (createdAt is! Timestamp) continue;

      final date = createdAt.toDate();

      final day = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final index = day.difference(firstDay).inDays;

      if (index >= 0 && index < 7) {
        counts[index]++;
      }
    }

    return counts;
  }

  // DATE LABELS FOR CHART
  List<String> _dayLabels() {
    final now = DateTime.now();

    return List.generate(7, (index) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));

      return '${date.day}/${date.month}';
    });
  }

  // DEPARTMENT-WISE COMPLAINT COUNTS
  Map<String, int> _departmentCounts(
    List<Map<String, dynamic>> complaints,
  ) {
    final counts = <String, int>{
      'Electrical': 0,
      'Plumbing': 0,
      'Furniture': 0,
      'Infrastructure': 0,
      'IT & Network': 0,
      'Cleanliness': 0,
    };

    for (final complaint in complaints) {
      final category =
          _text(complaint['category']).toLowerCase();

      if (category.contains('electric')) {
        counts['Electrical'] =
            counts['Electrical']! + 1;
      } else if (category.contains('plumb') ||
          category.contains('water')) {
        counts['Plumbing'] =
            counts['Plumbing']! + 1;
      } else if (category.contains('furniture')) {
        counts['Furniture'] =
            counts['Furniture']! + 1;
      } else if (category.contains('infrastructure') ||
          category.contains('building')) {
        counts['Infrastructure'] =
            counts['Infrastructure']! + 1;
      } else if (category.contains('internet') ||
          category.contains('network') ||
          category == 'it') {
        counts['IT & Network'] =
            counts['IT & Network']! + 1;
      } else if (category.contains('clean')) {
        counts['Cleanliness'] =
            counts['Cleanliness']! + 1;
      }
    }

    return counts;
  }

  // SHOW MESSAGE
  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }
}

// DEPARTMENT DATA MODEL
class _Department {
  final String name;
  final IconData icon;
  final Color color;
  final Color tint;

  const _Department(
    this.name,
    this.icon,
    this.color,
    this.tint,
  );
}

// CUSTOM LINE CHART
class _TrendPainter extends CustomPainter {
  final List<int> values;

  const _TrendPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 7.0;
    const right = 7.0;
    const top = 9.0;
    const bottom = 9.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final maxValue = values.fold<int>(
      4,
      (max, value) => value > max ? value : max,
    );

    // HORIZONTAL GRID LINES
    final gridPaint = Paint()
      ..color = const Color(0xFFE7EDF5)
      ..strokeWidth = 1;

    for (var row = 0; row < 4; row++) {
      final y = top + chartHeight * row / 3;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    if (values.isEmpty) return;

    // CALCULATE CHART POINTS
    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = left +
          chartWidth *
              (values.length == 1
                  ? 0
                  : index / (values.length - 1));

      final y = top +
          chartHeight -
          (values[index] / maxValue) * chartHeight;

      points.add(Offset(x, y));
    }

    // SHADED AREA BELOW THE LINE
    final area = Path()
      ..moveTo(
        points.first.dx,
        top + chartHeight,
      );

    for (final point in points) {
      area.lineTo(point.dx, point.dy);
    }

    area
      ..lineTo(
        points.last.dx,
        top + chartHeight,
      )
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x332B7DE0),
          Color(0x002B7DE0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromLTWH(
          0,
          top,
          size.width,
          chartHeight,
        ),
      );

    canvas.drawPath(area, fill);

    // DRAW BLUE TREND LINE
    final line = Path()
      ..moveTo(
        points.first.dx,
        points.first.dy,
      );

    for (var index = 1;
        index < points.length;
        index++) {
      line.lineTo(
        points[index].dx,
        points[index].dy,
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2475DC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(line, linePaint);

    // DRAW DATA POINTS
    final dot = Paint()
      ..color = const Color(0xFF2475DC);

    final center = Paint()
      ..color = Colors.white;

    for (final point in points) {
      canvas.drawCircle(point, 4, dot);
      canvas.drawCircle(point, 1.8, center);
    }
  }

  @override
  bool shouldRepaint(
    covariant _TrendPainter oldDelegate,
  ) {
    if (oldDelegate.values.length != values.length) {
      return true;
    }

    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) {
        return true;
      }
    }

    return false;
  }
}