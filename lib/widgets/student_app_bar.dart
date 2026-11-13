import 'package:flutter/material.dart';

class StudentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onDashboardTap;

  const StudentAppBar({
    super.key,
    this.onDashboardTap,
  });

  static const Color darkBlue = Color(0xFF102A56);
  static const Color orange = Color(0xFFFFA500);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      centerTitle: true,

      // College Logo
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/college_logo.jpeg',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.account_balance,
              color: darkBlue,
              size: 30,
            );
          },
        ),
      ),

      // CampusFix Branding
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'CAMPUS',
              style: TextStyle(
                color: darkBlue,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: 'FIX',
              style: TextStyle(
                color: orange,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),

      // Dashboard Button
      actions: [
        IconButton(
          onPressed: onDashboardTap,
          icon: const Icon(
            Icons.dashboard_outlined,
            color: darkBlue,
          ),
          tooltip: 'Dashboard',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}