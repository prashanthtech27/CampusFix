import 'package:flutter/material.dart';
import 'upload_images_page.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  static const Color primaryBlue = Color(0xFF0866E8);
  static const Color darkBlue = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color secondaryColor = Color(0xFF64748B);

  String? selectedCategory;

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Electrical',
      'description': 'Fan, Light, Power Supply',
      'icon': Icons.bolt,
      'color': const Color(0xFFFFC107),
    },
    {
      'name': 'Plumbing',
      'description': 'Water, Leakage, Washroom',
      'icon': Icons.water_drop,
      'color': const Color(0xFF0866E8),
    },
    {
      'name': 'Furniture',
      'description': 'Chair, Table, Bench',
      'icon': Icons.chair,
      'color': const Color(0xFFFF781F),
    },
    {
      'name': 'Infrastructure',
      'description': 'Classroom, Building, Wall',
      'icon': Icons.business,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'IT & Network',
      'description': 'Wi-Fi, Computer, Projector',
      'icon': Icons.wifi,
      'color': const Color(0xFF9810E8),
    },
    {
      'name': 'Cleanliness',
      'description': 'Garbage, Dustbin, Hygiene',
      'icon': Icons.delete,
      'color': const Color(0xFFEC4899),
    },
    {
      'name': 'Other',
      'description': 'Any other issue',
      'icon': Icons.more_horiz,
      'color': const Color(0xFF64748B),
    },
  ];

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  void _goToNextPage() {
  if (selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a complaint category'),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UploadImagesPage(
        selectedCategory: selectedCategory!,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: darkBlue,
          ),
        ),
        title: const Text(
          'Report an Issue',
          style: TextStyle(
            color: darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Select Issue Category',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose the category that best describes your problem.',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                ...categories.map(
                  (category) => _buildCategoryCard(category),
                ),
              ],
            ),
          ),

          // Bottom Next Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _goToNextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, size: 19),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final bool isSelected =
        selectedCategory == category['name'];

    final Color categoryColor = category['color'];

    return GestureDetector(
      onTap: () => _selectCategory(category['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            // Category Icon
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category['icon'],
                color: Colors.white,
                size: 27,
              ),
            ),

            const SizedBox(width: 13),

            // Category Name and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    category['description'],
                    style: const TextStyle(
                      color: secondaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? primaryBlue
                  : secondaryColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}