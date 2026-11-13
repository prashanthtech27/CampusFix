import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintDetailsPage extends StatelessWidget {
  final String complaintDocumentId;

  const ComplaintDetailsPage({
    super.key,
    required this.complaintDocumentId,
  });

  static const Color primaryColor = Color(0xFF0866E8);
  static const Color darkColor = Color(0xFF102A56);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Complaint Details',
          style: TextStyle(
            color: darkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: darkColor),
      ),

      body: FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('complaints')
            .doc(complaintDocumentId)
            .get(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Unable to load complaint details.'),
            );
          }

          final data = snapshot.data!.data()!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(data),

              const SizedBox(height: 20),

              _buildSection(
                'Complaint Information',
                [
                  _detailRow(
                    'Complaint ID',
                    data['complaintId'] ?? 'N/A',
                  ),
                  _detailRow(
                    'Issue Title',
                    data['title'] ?? 'N/A',
                  ),
                  _detailRow(
                    'Category',
                    data['category'] ?? 'N/A',
                  ),
                  _detailRow(
                    'Location',
                    data['location'] ?? 'N/A',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildSection(
                'Problem Description',
                [
                  Text(
                    data['description'] ?? 'No description available.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildSection(
                'Additional Information',
                [
                  _detailRow(
                    'Priority',
                    data['priority'] ?? 'N/A',
                  ),
                  _detailRow(
                    'Images Selected',
                    '${data['imageCount'] ?? 0}',
                  ),
                  _detailRow(
                    'Images Uploaded',
                    data['imagesUploaded'] == true ? 'Yes' : 'No',
                  ),
                  _detailRow(
                    'Submitted On',
                    _formatDate(data['createdAt']),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your complaint status will be updated '
                        'when the campus administration processes it.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'Reported';
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 45,
            color: color,
          ),
          const SizedBox(height: 12),
          const Text(
            'Current Status',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is! Timestamp) {
      return 'Date unavailable';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}