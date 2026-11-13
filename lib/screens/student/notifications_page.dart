import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'complaint_details_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const Color primaryColor = Color(0xFF0866E8);
  static const Color darkColor = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // MARK NOTIFICATION AS READ

  Future<void> _markAsRead(
    String notificationId,
    bool isRead,
  ) async {
    if (isRead) return;

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // OPEN COMPLAINT DETAILS

  void _openComplaint(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final complaintDocumentId =
        data['complaintDocumentId']?.toString();

    if (complaintDocumentId == null ||
        complaintDocumentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No complaint details are linked to this notification.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintDetailsPage(
          complaintDocumentId: complaintDocumentId,
        ),
      ),
    );
  }

  // HANDLE NOTIFICATION TAP

  Future<void> _handleNotificationTap(
    BuildContext context,
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _markAsRead(
        notificationId,
        data['isRead'] == true,
      );

      if (!context.mounted) return;

      _openComplaint(context, data);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update notification: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // DEBUG: LOGGED-IN USER

    debugPrint('========== NOTIFICATION DEBUG ==========');
    debugPrint('Logged-in UID: ${user?.uid}');

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view notifications.',
          ),
        ),
      );
    }

    // FIRESTORE NOTIFICATION STREAM

    final notificationStream = FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'recipientUid',
          isEqualTo: user.uid,
        )
        .snapshots();

    return Scaffold(
      backgroundColor: backgroundColor,

      // APP BAR

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: darkColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: darkColor,
        ),
      ),

      // NOTIFICATION STREAM

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationStream,

        builder: (context, snapshot) {
          // DEBUG INFORMATION

          debugPrint(
            'Connection State: ${snapshot.connectionState}',
          );

          debugPrint(
            'Has Error: ${snapshot.hasError}',
          );

          if (snapshot.hasError) {
            debugPrint(
              'FIRESTORE ERROR: ${snapshot.error}',
            );
          }

          if (snapshot.hasData) {
            debugPrint(
              'Documents Found: ${snapshot.data!.docs.length}',
            );

            for (var doc in snapshot.data!.docs) {
              debugPrint('Document ID: ${doc.id}');
              debugPrint('Document Data: ${doc.data()}');
            }
          }

          debugPrint('========================================');

          // LOADING STATE

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          // ERROR STATE

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                      'Unable to load notifications',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // GET NOTIFICATIONS

          final notifications =
              snapshot.data?.docs.toList() ?? [];

          // SORT LATEST FIRST

          notifications.sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];

            final aDate = aTime is Timestamp
                ? aTime.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);

            final bDate = bTime is Timestamp
                ? bTime.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);

            return bDate.compareTo(aDate);
          });

          // COUNT UNREAD NOTIFICATIONS

          final unreadCount = notifications.where((notification) {
            return notification.data()['isRead'] != true;
          }).length;

          // NOTIFICATION LIST

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(unreadCount),

              const SizedBox(height: 20),

              if (notifications.isEmpty)
                _buildEmptyState()
              else
                ...notifications.map((notification) {
                  final data = notification.data();

                  return _buildNotificationCard(
                    context,
                    notification.id,
                    data,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  // NOTIFICATION HEADER

  Widget _buildHeader(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: primaryColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay Updated!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  unreadCount == 0
                      ? 'You are all caught up.'
                      : '$unreadCount unread notifications',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NOTIFICATION CARD

  Widget _buildNotificationCard(
    BuildContext context,
    String notificationId,
    Map<String, dynamic> data,
  ) {
    final title =
        data['title']?.toString() ?? 'CampusFix Notification';

    final message =
        data['message']?.toString() ?? 'You have a new notification.';

    final type =
        data['type']?.toString() ?? 'general';

    final isRead = data['isRead'] == true;

    final createdAt = data['createdAt'];

    final date = createdAt is Timestamp
        ? _formatDate(createdAt.toDate())
        : 'Just now';

    final color = _getNotificationColor(type);

    final icon = _getNotificationIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white
            : const Color(0xFFEDF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead
              ? Colors.grey.shade200
              : primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(
          context,
          notificationId,
          data,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor:
                    color.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isRead ? 'Read' : 'Tap to view',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isRead
                            ? Colors.grey
                            : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              if (!isRead)
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 55,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 75,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 18),

          const Text(
            'No Notifications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),

          const SizedBox(height: 9),

          const Text(
            'We will notify you when there is an '
            'update regarding your complaints.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // NOTIFICATION COLORS

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'submitted':
        return Colors.blue;

      case 'assigned':
        return Colors.purple;

      case 'in_progress':
        return Colors.orange;

      case 'resolved':
        return Colors.green;

      default:
        return primaryColor;
    }
  }

  // NOTIFICATION ICONS

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'submitted':
        return Icons.assignment_turned_in_outlined;

      case 'assigned':
        return Icons.engineering_outlined;

      case 'in_progress':
        return Icons.pending_actions;

      case 'resolved':
        return Icons.check_circle_outline;

      default:
        return Icons.notifications_outlined;
    }
  }

  // DATE FORMAT

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year}  $hour:$minute';
  }
}
