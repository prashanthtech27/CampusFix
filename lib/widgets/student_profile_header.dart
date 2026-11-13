import 'package:flutter/material.dart';

class StudentProfileHeader extends StatelessWidget {
  final String name;
  final String usn;
  final String department;
  final String? profileImageUrl;

  const StudentProfileHeader({
    super.key,
    required this.name,
    required this.usn,
    required this.department,
    this.profileImageUrl,
  });

  static const Color darkBlue = Color(0xFF102A56);
  static const Color primaryBlue = Color(0xFF0866E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Student Profile Picture
          CircleAvatar(
            radius: 32,
          backgroundColor: primaryBlue.withValues(alpha: 0.1),
            backgroundImage:
                profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileImageUrl!)
                    : null,
            child: profileImageUrl == null || profileImageUrl!.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 38,
                    color: primaryBlue,
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Student Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$name!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  usn.isNotEmpty ? usn : 'USN not available',
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

