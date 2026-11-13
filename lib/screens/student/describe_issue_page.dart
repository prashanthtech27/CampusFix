import 'package:flutter/material.dart';
import 'complaint_sucess_page.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';

class DescribeIssuePage extends StatefulWidget {
  final String selectedCategory;
  final List<String> imagePaths;
  final String selectedLocation;

  const DescribeIssuePage({
    super.key,
    required this.selectedCategory,
    required this.imagePaths,
    required this.selectedLocation,
  });

  @override
  State<DescribeIssuePage> createState() =>
      _DescribeIssuePageState();
}

class _DescribeIssuePageState extends State<DescribeIssuePage> {
  static const Color primaryBlue = Color(0xFF0866E8);
  static const Color darkBlue = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color secondaryColor = Color(0xFF64748B);
  final AuthService _authService = AuthService();

final ComplaintService _complaintService = ComplaintService();

bool isSubmitting = false;
  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String selectedPriority = 'Medium';

  final List<Map<String, dynamic>> priorities = [
    {
      'name': 'Low',
      'icon': Icons.arrow_downward,
      'color': const Color(0xFF64748B),
    },
    {
      'name': 'Medium',
      'icon': Icons.shield,
      'color': const Color(0xFF0866E8),
    },
    {
      'name': 'High',
      'icon': Icons.local_fire_department,
      'color': const Color(0xFFFF781F),
    },
    {
      'name': 'Critical',
      'icon': Icons.emergency,
      'color': const Color(0xFFEF4444),
    },
  ];

  void _selectPriority(String priority) {
    setState(() {
      selectedPriority = priority;
    });
  }

  Future<void> _submitComplaint() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (isSubmitting) return;

  FocusScope.of(context).unfocus();

  setState(() {
    isSubmitting = true;
  });

  try {
    // Get the currently logged-in student.
    final user = _authService.currentUser;

    if (user == null) {
      throw Exception('Please login before submitting a complaint.');
    }

    // Fetch student profile from Firestore.
    final profileSnapshot =
        await _authService.getUserProfile();

    if (!profileSnapshot.exists) {
      throw Exception('Student profile not found.');
    }

    final studentData = profileSnapshot.data()!;

    final String studentName =
        studentData['name']?.toString() ?? 'Student';

    final String studentUSN =
        studentData['usn']?.toString() ??
        studentData['cetNumber']?.toString() ??
        '';

    // Submit complaint to Firebase.
    final String complaintId =
        await _complaintService.submitComplaint(
      studentUid: user.uid,
      studentName: studentName,
      studentUSN: studentUSN,
      category: widget.selectedCategory,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: widget.selectedLocation,
      priority: selectedPriority,
      imagePaths: widget.imagePaths,
    );

    if (!mounted) return;

    // Navigate to success page only after successful submission.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintSuccessPage(
          complaintId: complaintId,
          title: _titleController.text.trim(),
          category: widget.selectedCategory,
          location: widget.selectedLocation,
          priority: selectedPriority,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complaint submission failed: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }
}

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
          'Describe the Issue',
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

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Issue title
                    _buildLabel('Issue Title'),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _titleController,
                      maxLength: 100,

                      decoration: _inputDecoration(
                        hint: 'Enter issue title',
                      ).copyWith(
                        counterText: '',
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter an issue title';
                        }

                        if (value.trim().length < 5) {
                          return 'Title must contain at least 5 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Detailed description
                    _buildLabel('Detailed Description'),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _descriptionController,

                      maxLines: 6,
                      maxLength: 500,

                      onChanged: (value) {
                        setState(() {});
                      },

                      decoration: _inputDecoration(
                        hint:
                            'Describe the problem in detail...',
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please describe the problem';
                        }

                        if (value.trim().length < 10) {
                          return 'Description must contain at least 10 characters';
                        }

                        return null;
                      },
                    ),

                    // Character count
                    Align(
                      alignment: Alignment.centerRight,

                      child: Text(
                        '${_descriptionController.text.length}/500',
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Priority
                    Row(
                      children: [
                        _buildLabel('Priority'),

                        const SizedBox(width: 5),

                        const Text(
                          '(Optional)',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Priority cards
                    Row(
                      children: priorities.map((priority) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 7,
                            ),
                            child: _buildPriorityCard(priority),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    // Complaint summary
                    _buildComplaintSummary(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // Section label
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: darkBlue,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Input decoration
  InputDecoration _inputDecoration({
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: secondaryColor,
        fontSize: 12,
      ),

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.all(13),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),
    );
  }

  // Priority selection card
  Widget _buildPriorityCard(Map<String, dynamic> priority) {
    final bool isSelected =
        selectedPriority == priority['name'];

    final Color priorityColor = priority['color'];

    return GestureDetector(
      onTap: () {
        _selectPriority(priority['name']);
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 4,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? priorityColor.withValues(alpha: 0.12)
              : Colors.white,

          borderRadius: BorderRadius.circular(9),

          border: Border.all(
            color: isSelected
                ? priorityColor
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),

        child: Column(
          children: [
            Icon(
              priority['icon'],
              color: priorityColor,
              size: 22,
            ),

            const SizedBox(height: 7),

            Text(
              priority['name'],
              textAlign: TextAlign.center,

              style: TextStyle(
                color: priorityColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Complaint summary
  Widget _buildComplaintSummary() {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complaint Summary',
            style: TextStyle(
              color: darkBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _summaryRow(
            'Category',
            widget.selectedCategory,
          ),

          _summaryRow(
            'Location',
            widget.selectedLocation,
          ),

          _summaryRow(
            'Images',
            '${widget.imagePaths.length} selected',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ),

          const Text(': '),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Submit button
  Widget _buildSubmitButton() {
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
          onPressed: isSubmitting ? null : _submitComplaint,

          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          child: isSubmitting
    ? const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
    : const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Submit Complaint',
            style: TextStyle(
              fontSize: 14,
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