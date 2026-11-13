import 'package:flutter/material.dart';
import 'student_home_page.dart';

class ComplaintSuccessPage extends StatelessWidget {
  final String complaintId;
  final String title;
  final String category;
  final String location;
  final String priority;

  const ComplaintSuccessPage({
    super.key,
    required this.complaintId,
    required this.title,
    required this.category,
    required this.location,
    required this.priority,
  });

  static const Color primaryBlue = Color(0xFF0866E8);
  static const Color darkBlue = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color greenColor = Color(0xFF10B981);
  static const Color secondaryColor = Color(0xFF64748B);
  void _showComplaintDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Complaint Details',
            style: TextStyle(
              color: darkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complaint ID: $complaintId'),
              const SizedBox(height: 10),
              Text('Title: $title'),
              const SizedBox(height: 10),
              Text('Category: $category'),
              const SizedBox(height: 10),
              Text('Location: $location'),
              const SizedBox(height: 10),
              Text('Priority: $priority'),
              const SizedBox(height: 10),
              const Text('Status: Reported'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _goToDashboard(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentHomePage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success icon
              Container(
                height: 105,
                width: 105,
                decoration: const BoxDecoration(
                  color: greenColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 65,
                ),
              ),

              const SizedBox(height: 30),

              // Success heading
              const Text(
                'Complaint Submitted\nSuccessfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 18),

              // Description
              const Text(
                'Your complaint has been registered '
                'and will be assigned to the maintenance staff.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 30),

              // Complaint ID card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Complaint ID',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),

                    SelectableText(
                      '#$complaintId',
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // View Complaint button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _showComplaintDetails(context);
                  },
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
                        'View Complaint',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Go to Dashboard button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _goToDashboard(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(
                      color: primaryBlue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}