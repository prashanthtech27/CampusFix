import 'package:flutter/material.dart';
import 'describe_issue_page.dart';
class SelectLocationPage extends StatefulWidget {
  final String selectedCategory;
  final List<String> imagePaths;

  const SelectLocationPage({
    super.key,
    required this.selectedCategory,
    required this.imagePaths,
  });

  @override
  State<SelectLocationPage> createState() =>
      _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  static const Color primaryBlue = Color(0xFF0866E8);
  static const Color darkBlue = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color secondaryColor = Color(0xFF64748B);

  final TextEditingController _searchController =
      TextEditingController();

  String? selectedBlock;
  String? selectedRoom;

  final List<Map<String, dynamic>> campusLocations = [
    {
      'name': 'Block A',
      'icon': Icons.business,
      'rooms': ['Room 101', 'Room 102', 'Room 204', 'Room 305'],
      'position': const Alignment(-0.65, 0.0),
    },
    {
      'name': 'Block B',
      'icon': Icons.business,
      'rooms': ['Room 101', 'Room 205', 'Room 301'],
      'position': const Alignment(-0.65, 0.55),
    },
    {
      'name': 'Block C',
      'icon': Icons.business,
      'rooms': ['Room 101', 'Room 202', 'Room 303'],
      'position': const Alignment(-0.65, -0.65),
    },
    {
      'name': 'Library',
      'icon': Icons.local_library,
      'rooms': ['Ground Floor', 'First Floor', 'Second Floor'],
      'position': const Alignment(0.0, -0.65),
    },
    {
      'name': 'Library B',
      'icon': Icons.local_library,
      'rooms': ['Reading Room', 'Computer Section'],
      'position': const Alignment(0.0, -0.05),
    },
    {
      'name': 'Canteen',
      'icon': Icons.restaurant,
      'rooms': ['Main Hall', 'Kitchen'],
      'position': const Alignment(0.65, -0.05),
    },
    {
      'name': 'Playground',
      'icon': Icons.sports_soccer,
      'rooms': ['Main Ground', 'Basketball Court'],
      'position': const Alignment(-0.65, 0.95),
    },
    {
      'name': 'Admin Block',
      'icon': Icons.account_balance,
      'rooms': ['Office', 'Reception', 'Room 101'],
      'position': const Alignment(0.45, 0.65),
    },
  ];

  List<Map<String, dynamic>> get filteredLocations {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) return campusLocations;

    return campusLocations.where((location) {
      final name = location['name'].toString().toLowerCase();

      final rooms = (location['rooms'] as List<String>)
          .join(' ')
          .toLowerCase();

      return name.contains(query) || rooms.contains(query);
    }).toList();
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      selectedBlock = location['name'];
      selectedRoom = null;
    });

    _showRoomSelection(location);
  }

  void _showRoomSelection(Map<String, dynamic> location) {
    final List<String> rooms = location['rooms'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select location in ${location['name']}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),

              const SizedBox(height: 15),

              ...rooms.map(
                (room) => ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: primaryBlue,
                  ),
                  title: Text(room),
                  onTap: () {
                    setState(() {
                      selectedBlock = location['name'];
                      selectedRoom = room;
                    });

                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToNextPage() {
  if (selectedBlock == null || selectedRoom == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please select a campus location and room.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DescribeIssuePage(
        selectedCategory: widget.selectedCategory,
        imagePaths: widget.imagePaths,
        selectedLocation: '$selectedBlock - $selectedRoom',
      ),
    ),
  );
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Select Location',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSearchField(),

                  const SizedBox(height: 15),

                  _buildCampusMap(),

                  const SizedBox(height: 20),

                  _buildSelectedLocation(),
                ],
              ),
            ),
          ),

          _buildNextButton(),
        ],
      ),
    );
  }

  // Search field.
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Search location (e.g., Block A, Room 204)',
        hintStyle: const TextStyle(
          fontSize: 12,
          color: secondaryColor,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: secondaryColor,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }

  // Campus location selector.
  Widget _buildCampusMap() {
    final locations = filteredLocations;

    return Container(
      height: 270,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: locations.isEmpty
          ? const Center(
              child: Text(
                'No locations found',
                style: TextStyle(color: secondaryColor),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.spaceAround,
                children: locations.map((location) {
                  final isSelected =
                      selectedBlock == location['name'];

                  return GestureDetector(
                    onTap: () => _selectLocation(location),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryBlue
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? primaryBlue
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            location['icon'],
                            size: 15,
                            color: isSelected
                                ? Colors.white
                                : darkBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            location['name'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  // Selected location display.
  Widget _buildSelectedLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Selected Location',
            style: TextStyle(
              color: darkBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: darkBlue,
                size: 23,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  selectedBlock == null
                      ? 'Choose a campus location'
                      : selectedRoom == null
                          ? selectedBlock!
                          : '$selectedBlock - $selectedRoom',
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: secondaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bottom Next button.
  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        20,
      ),
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
    );
  }
}