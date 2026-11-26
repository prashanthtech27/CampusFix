import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StaffNotificationsPage extends StatefulWidget {
  const StaffNotificationsPage({super.key});

  @override
  State<StaffNotificationsPage> createState() =>
      _StaffNotificationsPageState();
}

class _StaffNotificationsPageState
    extends State<StaffNotificationsPage> {
  static const Color navy = Color(0xFF092B65);
  static const Color blue = Color(0xFF075DD5);
  static const Color background = Color(0xFFF3F6FC);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final String? _currentUid =
      FirebaseAuth.instance.currentUser?.uid;

  // Mark one notification as read.
  Future<void> _markAsRead(String documentId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(documentId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update notification: $e'),
        ),
      );
    }
  }

  // Mark all notifications as read.
  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final doc in docs) {
        final data = doc.data();

        if (data['isRead'] != true) {
          batch.update(doc.reference, {
            'isRead': true,
          });
        }
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Format notification date.
  String _formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) {
      return 'Date unavailable';
    }

    final date = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(date);

    if (difference.inMinutes < 1 && !difference.isNegative) {
      return 'Just now';
    }

    if (difference.inHours < 1 && !difference.isNegative) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    }

    if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // Notification icon based on type.
  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'submitted':
        return Icons.send_rounded;

      case 'assigned':
        return Icons.assignment_ind_rounded;

      case 'accepted':
        return Icons.check_circle_outline_rounded;

      case 'declined':
        return Icons.cancel_outlined;

      case 'resolved':
        return Icons.task_alt_rounded;

      case 'closed':
        return Icons.lock_outline_rounded;

      default:
        return Icons.notifications_active_outlined;
    }
  }

  // Notification card.
  Widget _notificationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final String title =
        data['title']?.toString() ?? 'Notification';

    final String message =
        data['message']?.toString() ?? '';

    final String type =
        data['type']?.toString() ?? '';

    final bool isRead = data['isRead'] == true;

    final String date = _formatDate(data['createdAt']);

    return InkWell(
      onTap: () {
        if (!isRead) {
          _markAsRead(document.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : blue.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: blue,
                size: 23,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          height: 9,
                          width: 9,
                          decoration: const BoxDecoration(
                            color: blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view notifications.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('notifications')
            .where('recipientUid', isEqualTo: _currentUid)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: blue,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load notifications.',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final unreadCount = docs.where((doc) {
            return doc.data()['isRead'] != true;
          }).length;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 65,
                    color: Colors.blueGrey.shade200,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'No Notifications Yet',
                    style: TextStyle(
                      color: navy,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'You will see your updates here.',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary section.
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: blue,
                      size: 28,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${docs.length} Notifications',
                            style: const TextStyle(
                              color: navy,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '$unreadCount unread notifications',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () => _markAllAsRead(docs),
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(
                            color: blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Notification list.
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _notificationCard(docs[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}