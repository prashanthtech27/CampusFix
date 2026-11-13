import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CoordinatorAnalyticsPage extends StatefulWidget {
  const CoordinatorAnalyticsPage({super.key});

  @override
  State<CoordinatorAnalyticsPage> createState() =>
      _CoordinatorAnalyticsPageState();
}

class _CoordinatorAnalyticsPageState
    extends State<CoordinatorAnalyticsPage> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

 static const Color navy = Color(0xFF09213F);
static const Color blue = Color(0xFF075DD5);
static const Color background = Color(0xFFF4F7FC);

static const Color green = Color(0xFF00A879);
static const Color orange = Color(0xFFFFB52E);


  String selectedPeriod = 'Last 30 Days';
  String selectedDepartment = 'All Departments';

  final List<String> periods = [
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
  ];

  final List<Color> chartColors = [
    const Color(0xFF2878E5),
    const Color(0xFF00B894),
    const Color(0xFFFFB52E),
    const Color(0xFF9B59B6),
    const Color(0xFFE74C3C),
    const Color(0xFF18A6B8),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('complaints')
              .snapshots(),

          builder: (context, snapshot) {

            if (snapshot.hasError) {
              return _errorView(snapshot.error.toString());
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final documents = snapshot.data?.docs ?? [];

            final allRecords = documents
                .map((doc) => doc.data())
                .toList();

            final filteredRecords =
                _filterRecords(allRecords);

            final total = filteredRecords.length;

            final resolved = filteredRecords.where((item) {
              return _status(item) == 'Resolved';
            }).length;

            final inProgress = filteredRecords.where((item) {
              return _status(item) == 'In Progress';
            }).length;

            final pending = filteredRecords.where((item) {
              return _status(item) == 'Reported';
            }).length;

            final overdue = filteredRecords.where((item) {
              return _status(item) == 'Overdue';
            }).length;

            final averageResolution =
                _averageResolution(filteredRecords);

            final departmentCounts =
                _departmentCounts(filteredRecords);

            final monthlyCounts =
                _monthlyCounts(filteredRecords);

            final resolutionTrend =
                _resolutionTrend(filteredRecords);

            return LayoutBuilder(
              builder: (context, constraints) {

                final desktop = constraints.maxWidth >= 900;

                return Row(
                  children: [

                    if (desktop)
                      _sidebar(),

                    Expanded(
                      child: Column(
                        children: [

                          _header(desktop),

                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.all(
                                desktop ? 22 : 14,
                              ),

                              children: [

                                _filterSection(),

                                const SizedBox(height: 18),

                                _kpiSection(
                                  total,
                                  resolved,
                                  averageResolution,
                                  desktop,
                                ),

                                const SizedBox(height: 20),

                                _chartRow(
                                  desktop,
                                  _departmentChart(
                                    departmentCounts,
                                    total,
                                  ),
                                  _statusChart(
                                    resolved,
                                    inProgress,
                                    pending,
                                    overdue,
                                    total,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                _chartRow(
                                  desktop,
                                  _monthlyChart(monthlyCounts),
                                  _resolutionChart(
                                    resolutionTrend,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                _insightCard(
                                  total,
                                  resolved,
                                  pending,
                                  inProgress,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // SIDEBAR
  // ==========================================

  Widget _sidebar() {
    return Container(
      width: 205,
      color: navy,

      child: Column(
        children: [

          const SizedBox(height: 25),

          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFFFC928),
            child: Icon(
              Icons.account_balance,
              color: navy,
              size: 29,
            ),
          ),

          const SizedBox(height: 9),

          const Text(
            'CampusFix',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 30),

          _sidebarItem(
            Icons.dashboard_rounded,
            'Dashboard',
            false,
          ),

          _sidebarItem(
            Icons.people_alt_rounded,
            'Users',
            false,
          ),

          _sidebarItem(
            Icons.assignment_rounded,
            'Complaints',
            false,
          ),

          _sidebarItem(
            Icons.assignment_ind_rounded,
            'Assignments',
            false,
          ),

          _sidebarItem(
            Icons.analytics_rounded,
            'Analytics',
            true,
          ),

          _sidebarItem(
            Icons.description_rounded,
            'Reports',
            false,
          ),

          _sidebarItem(
            Icons.settings_rounded,
            'Settings',
            false,
          ),

          const Spacer(),

          _sidebarItem(
            Icons.logout_rounded,
            'Logout',
            false,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String title,
    bool selected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),

      child: ListTile(
        dense: true,
        selected: selected,

        selectedTileColor: blue,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),

        leading: Icon(
          icon,
          color: selected ? Colors.white : Colors.white70,
          size: 19,
        ),

        title: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),

        onTap: () {
          if (title == 'Logout') {
            _logout();
          } else if (title != 'Analytics') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$title page will be connected next.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _header(bool desktop) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,

      child: Row(
        children: [

          if (!desktop)
            const Icon(
              Icons.analytics_rounded,
              color: navy,
            ),

          if (!desktop)
            const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Analytics',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No new notifications.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: navy,
            ),
          ),

          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE6EEFF),
            child: Icon(
              Icons.person,
              color: blue,
              size: 19,
            ),
          ),

          const SizedBox(width: 7),

          const Text(
            'Admin',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FILTER SECTION
  // ==========================================

  Widget _filterSection() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,

      children: [

        _filterDropdown(
          selectedPeriod,
          periods,
          (value) {
            if (value == null) return;

            setState(() {
              selectedPeriod = value;
            });
          },
        ),

        _filterDropdown(
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
    );
  }

  Widget _filterDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),

          style: const TextStyle(
            fontSize: 11,
            color: navy,
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
        ),
      ),
    );
  }

  // ==========================================
  // FILTER FIRESTORE RECORDS
  // ==========================================

  List<Map<String, dynamic>> _filterRecords(
    List<Map<String, dynamic>> records,
  ) {
    final now = DateTime.now();

    DateTime? startDate;

    switch (selectedPeriod) {
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;

      case 'Last 30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;

      case 'Last 90 Days':
        startDate = now.subtract(const Duration(days: 90));
        break;

      case 'All Time':
        startDate = null;
        break;
    }

    return records.where((item) {

      final timestamp = item['createdAt'];

      if (startDate != null) {
        if (timestamp is! Timestamp) return false;

        if (timestamp.toDate().isBefore(startDate)) {
          return false;
        }
      }

      if (selectedDepartment != 'All Departments') {
        final department = _departmentForCategory(
          item['category']?.toString() ?? '',
        );

        if (department != selectedDepartment) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ==========================================
  // KPI SECTION
  // ==========================================

  Widget _kpiSection(
    int total,
    int resolved,
    Duration? average,
    bool desktop,
  ) {
    final resolutionRate = total == 0
        ? 0.0
        : resolved / total * 100;

    final averageText = average == null
        ? 'N/A'
        : average.inHours >= 24
            ? '${average.inDays} days'
            : '${average.inHours} hrs';

    return LayoutBuilder(
      builder: (context, constraints) {

        final columns = desktop ? 3 : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: desktop ? 2.5 : 3.0,

          children: [

            _kpiCard(
              'Total Complaints',
              total.toString(),
              Icons.description_rounded,
              blue,
              '+${resolutionRate.toStringAsFixed(0)}% resolved',
            ),

            _kpiCard(
              'Resolved',
              resolved.toString(),
              Icons.check_circle_rounded,
              const Color(0xFF00A879),
              '${resolutionRate.toStringAsFixed(1)}% resolution',
            ),

            _kpiCard(
              'Avg. Resolution Time',
              averageText,
              Icons.timer_rounded,
              orange,
              'Based on resolved complaints',
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEDF0F5),
        ),
      ),

      child: Row(
        children: [

          CircleAvatar(
            radius: 21,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blueGrey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
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
  // CHART ROW
  // ==========================================

  Widget _chartRow(
    bool desktop,
    Widget first,
    Widget second,
  ) {
    if (desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Expanded(child: first),

          const SizedBox(width: 15),

          Expanded(child: second),
        ],
      );
    }

    return Column(
      children: [
        first,
        const SizedBox(height: 15),
        second,
      ],
    );
  }

  // ==========================================
  // DEPARTMENT DONUT CHART
  // ==========================================

  Widget _departmentChart(
    Map<String, int> counts,
    int total,
  ) {
    final entries = counts.entries
        .where((entry) => entry.value > 0)
        .toList();

    return _chartCard(
      'Complaints by Department',
      SizedBox(
        height: 205,

        child: Row(
          children: [

            Expanded(
              flex: 5,

              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 38,
                  sectionsSpace: 2,

                  sections: entries.isEmpty
                      ? [
                          PieChartSectionData(
                            value: 1,
                            color: Colors.grey.shade300,
                            radius: 22,
                            showTitle: false,
                          ),
                        ]
                      : entries.asMap().entries.map((entry) {

                          final index = entry.key;
                          final item = entry.value;

                          return PieChartSectionData(
                            value: item.value.toDouble(),
                            color: chartColors[
                                index % chartColors.length],
                            radius: 22,
                            showTitle: false,
                          );
                        }).toList(),
                ),
              ),
            ),

            Expanded(
              flex: 6,

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: entries.isEmpty
                    ? [
                        const Text(
                          'No department data',
                          style: TextStyle(fontSize: 11),
                        ),
                      ]
                    : entries.asMap().entries.map((entry) {

                        final index = entry.key;
                        final item = entry.value;

                        final percentage = total == 0
                            ? 0
                            : item.value / total * 100;

                        return _legendItem(
                          item.key,
                          '${percentage.toStringAsFixed(0)}%',
                          chartColors[
                              index % chartColors.length],
                        );
                      }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATUS DONUT CHART
  // ==========================================

  Widget _statusChart(
    int resolved,
    int inProgress,
    int pending,
    int overdue,
    int total,
  ) {
    final values = [
      resolved,
      inProgress,
      pending,
      overdue,
    ];

    final colors = [
      const Color(0xFF00A879),
      blue,
      const Color(0xFFFFB52E),
      const Color(0xFFE74C3C),
    ];

    final labels = [
      'Resolved',
      'In Progress',
      'Pending',
      'Overdue',
    ];

    return _chartCard(
      'Status Distribution',

      SizedBox(
        height: 205,

        child: Row(
          children: [

            Expanded(
              flex: 5,

              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 38,
                  sectionsSpace: 2,

                  sections: total == 0
                      ? [
                          PieChartSectionData(
                            value: 1,
                            color: Colors.grey.shade300,
                            radius: 22,
                            showTitle: false,
                          ),
                        ]
                      : List.generate(4, (index) {

                          return PieChartSectionData(
                            value: values[index].toDouble(),
                            color: colors[index],
                            radius: 22,
                            showTitle: false,
                          );
                        }),
                ),
              ),
            ),

            Expanded(
              flex: 6,

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: List.generate(4, (index) {

                  final percentage = total == 0
                      ? 0
                      : values[index] / total * 100;

                  return _legendItem(
                    labels[index],
                    '${percentage.toStringAsFixed(0)}%',
                    colors[index],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LEGEND
  // ==========================================

  Widget _legendItem(
    String title,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),

      child: Row(
        children: [

          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: navy,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MONTHLY BAR CHART
  // ==========================================

  Map<String, List<int>> _monthlyCounts(
    List<Map<String, dynamic>> records,
  ) {
    final now = DateTime.now();

    final result = <String, List<int>>{};

    for (int i = 3; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);

      final key = _monthName(month.month);

      result[key] = [0, 0];
    }

    for (final item in records) {
      final created = item['createdAt'];

      if (created is! Timestamp) continue;

      final date = created.toDate();

      final key = _monthName(date.month);

      if (!result.containsKey(key)) continue;

      result[key]![0]++;

      if (_status(item) == 'Resolved') {
        result[key]![1]++;
      }
    }

    return result;
  }

  Widget _monthlyChart(
    Map<String, List<int>> monthly,
  ) {
    final entries = monthly.entries.toList();

    final maxValue = entries.fold<int>(
      0,
      (previous, entry) {
        final maximum = entry.value.fold<int>(
          0,
          (a, b) => a > b ? a : b,
        );

        return maximum > previous ? maximum : previous;
      },
    );

    return _chartCard(
      'Monthly Complaints Trend',

      SizedBox(
        height: 220,

        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                _legendItem(
                  'Reported',
                  '',
                  blue,
                ),

                const SizedBox(width: 15),

                _legendItem(
                  'Resolved',
                  '',
                  const Color(0xFF00B894),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: (maxValue + 2).toDouble(),
                  minY: 0,

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),

                  borderData: FlBorderData(
                    show: false,
                  ),

                  barGroups: List.generate(
                    entries.length,
                    (index) {

                      final values = entries[index].value;

                      return BarChartGroupData(
                        x: index,

                        barsSpace: 4,

                        barRods: [

                          BarChartRodData(
                            toY: values[0].toDouble(),
                            color: blue,
                            width: 9,
                            borderRadius:
                                BorderRadius.circular(3),
                          ),

                          BarChartRodData(
                            toY: values[1].toDouble(),
                            color: const Color(0xFF00B894),
                            width: 9,
                            borderRadius:
                                BorderRadius.circular(3),
                          ),
                        ],
                      );
                    },
                  ),

                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),

                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.blueGrey,
                            ),
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 ||
                              index >= entries.length) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding:
                                const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[index].key,
                              style: const TextStyle(
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RESOLUTION LINE CHART
  // ==========================================

  Map<String, double> _resolutionTrend(
    List<Map<String, dynamic>> records,
  ) {
    final now = DateTime.now();

    final result = <String, List<int>>{};

    for (int i = 3; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);

      result[_monthName(month.month)] = [0, 0];
    }

    for (final item in records) {
      if (_status(item) != 'Resolved') continue;

      final created = item['createdAt'];
      final resolved = item['resolvedAt'];

      if (created is! Timestamp ||
          resolved is! Timestamp) {
        continue;
      }

      final start = created.toDate();
      final end = resolved.toDate();

      final difference = end.difference(start);

      if (difference.isNegative) continue;

      final key = _monthName(end.month);

      if (!result.containsKey(key)) continue;

      result[key]![0] += difference.inHours;
      result[key]![1]++;
    }

    return result.map((key, value) {
      final average = value[1] == 0
          ? 0.0
          : value[0] / value[1];

      return MapEntry(key, average);
    });
  }

  Widget _resolutionChart(
    Map<String, double> trend,
  ) {
    final entries = trend.entries.toList();

    final maximum = entries.fold<double>(
      0,
      (previous, entry) =>
          entry.value > previous
              ? entry.value
              : previous,
    );

    final spots = entries.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.value,
      );
    }).toList();

    return _chartCard(
      'Average Resolution Time',

      SizedBox(
        height: 220,

        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maximum <= 0 ? 10 : maximum * 1.3,

            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
            ),

            borderData: FlBorderData(
              show: false,
            ),

            lineBarsData: [

              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: blue,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: blue.withValues(alpha: 0.08),
                ),
              ),
            ],

            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),

              rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),

              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 9,
                      ),
                    );
                  },
                ),
              ),

              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,

                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();

                    if (index < 0 ||
                        index >= entries.length) {
                      return const SizedBox();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        entries[index].key,
                        style: const TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CHART CARD
  // ==========================================

  Widget _chartCard(
    String title,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),

        border: Border.all(
          color: const Color(0xFFEDF0F5),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: navy,
            ),
          ),

          const SizedBox(height: 13),

          child,
        ],
      ),
    );
  }

  // ==========================================
  // INSIGHTS
  // ==========================================

  Widget _insightCard(
    int total,
    int resolved,
    int pending,
    int inProgress,
  ) {
    final rate = total == 0
        ? 0.0
        : resolved / total * 100;

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            'Key Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),

          const SizedBox(height: 12),

          _insightRow(
            'Resolution Rate',
            '${rate.toStringAsFixed(1)}%',
            green,
          ),

          _insightRow(
            'Pending Complaints',
            pending.toString(),
            orange,
          ),

          _insightRow(
            'Active Complaints',
            inProgress.toString(),
            blue,
          ),
        ],
      ),
    );
  }

  Widget _insightRow(
    String title,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
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

  // ==========================================
  // HELPERS
  // ==========================================

  String _status(Map<String, dynamic> item) {
    return item['status']?.toString() ?? 'Reported';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return months[month - 1];
  }

  Duration? _averageResolution(
    List<Map<String, dynamic>> records,
  ) {
    var totalHours = 0;
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

      totalHours += difference.inHours;
      count++;
    }

    if (count == 0) return null;

    return Duration(
      hours: totalHours ~/ count,
    );
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
    await FirebaseFirestore.instance
        .waitForPendingWrites();

    // Use Firebase Authentication directly.
    // The root authentication screen should
    // handle navigation after sign-out.

    try {
      // Import firebase_auth if using this action.
      // Connected in the next integration step.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Logout will use the main coordinator authentication flow.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // ==========================================
  // ERROR VIEW
  // ==========================================

  Widget _errorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Text(
          'Unable to load analytics:\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}