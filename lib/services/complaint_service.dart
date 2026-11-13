import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> submitComplaint({
    required String studentUid,
    required String studentName,
    required String studentUSN,
    required String category,
    required String title,
    required String description,
    required String location,
    required String priority,
    required List<String> imagePaths,
  }) async {
    try {
      // Generate a unique Firestore document ID.
      final complaintRef = _firestore.collection('complaints').doc();

      // Generate a readable complaint ID.
      final String complaintId =
          'CFX${complaintRef.id.substring(0, 8).toUpperCase()}';

      final Map<String, dynamic> complaintData = {
        'complaintId': complaintId,
        'studentUid': studentUid,
        'studentName': studentName,
        'studentUSN': studentUSN,
        'category': category,
        'title': title.trim(),
        'description': description.trim(),
        'location': location,
        'priority': priority,

        // Images remain on the student's device for now.
        'imageUrls': [],
        'imageCount': imagePaths.length,
        'imagesUploaded': false,

        // Initial complaint status.
        'status': 'Reported',

        // Timestamps and assignment details.
        'createdAt': FieldValue.serverTimestamp(),
        'assignedStaffUid': null,
        'resolutionImages': [],
        'resolutionComment': null,
        'resolvedAt': null,
      };

      await complaintRef.set(complaintData);

      return complaintId;
    } catch (e) {
      throw Exception('Failed to submit complaint: $e');
    }
  }
}