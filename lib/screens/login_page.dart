import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'register_page.dart';
import '../services/auth_service.dart';
import 'coordinator/coordinator_dashboard_page.dart';
import 'student/student_home_page.dart';
import 'staff/staff_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  final TextEditingController _usnController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // SELECTED ACCOUNT TYPE
  String _selectedRole = 'student';

  static const Color navy = Color(0xFF092B65);
  static const Color blue = Color(0xFF075DD5);
  static const Color yellow = Color(0xFFFFC928);

  @override
  void dispose() {
    _usnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // LOGIN FUNCTION
  // --------------------------------------------------

  Future<void> _login() async {
    if (_isLoading) return;

    final form = _formKey.currentState;

    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('CAMPUSFIX: Starting $_selectedRole login...');

      late UserCredential credential;

      // STEP 1: AUTHENTICATION BASED ON SELECTED ROLE

      switch (_selectedRole) {
        case 'student':
          credential = await _authService.loginStudent(
            identifier: _usnController.text.trim(),
            password: _passwordController.text,
          );
          break;

        case 'coordinator':
          credential = await _authService.loginCoordinator(
            email: _usnController.text.trim(),
            password: _passwordController.text,
          );
          break;

        case 'staff':
          credential = await _authService.loginStaff(
            email: _usnController.text.trim(),
            password: _passwordController.text,
          );
          break;

        default:
          throw Exception('Invalid account type.');
      }

      final user = credential.user;

      if (user == null) {
        throw Exception('Firebase did not return an authenticated user.');
      }

      debugPrint('CAMPUSFIX: Authentication successful. UID: ${user.uid}');

      if (!mounted) return;

      // STEP 2: FETCH FIRESTORE USER PROFILE

      debugPrint('CAMPUSFIX: Fetching profile for UID: ${user.uid}');

      final profile = await _authService
          .getUserProfile(uid: user.uid)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      // STEP 3: CHECK PROFILE EXISTENCE

      final userData = profile.data();

      if (!profile.exists || userData == null) {
        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'Your profile was not found. '
          'Please contact the administrator.',
          Colors.red,
        );

        return;
      }

      // STEP 4: VERIFY FIREBASE UID

      final storedUid = userData['uid']?.toString();

      if (storedUid != null && storedUid.isNotEmpty && storedUid != user.uid) {
        debugPrint(
          'CAMPUSFIX: UID mismatch. '
          'Auth=${user.uid}, Firestore=$storedUid',
        );

        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'Your account profile is inconsistent. '
          'Contact the administrator.',
          Colors.red,
        );

        return;
      }

      // STEP 5: VERIFY USER ROLE

      final role = userData['role']?.toString().trim().toLowerCase();

      debugPrint('CAMPUSFIX: User role = $role');

      if (role != _selectedRole) {
        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'This account does not have $_selectedRole access.',
          Colors.red,
        );

        return;
      }

      // STEP 6: GET USER NAME

      final userName = userData['name']?.toString() ?? 'User';

      debugPrint('CAMPUSFIX: Welcome $userName');

      if (!mounted) return;

      // STEP 7: ROLE-BASED NAVIGATION

      switch (role) {
        case 'student':
          debugPrint('CAMPUSFIX: Opening Student Homepage.');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const StudentHomePage()),
          );

          break;

        case 'coordinator':
          debugPrint('CAMPUSFIX: Opening Coordinator Dashboard.');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const CoordinatorDashboardPage(),
            ),
          );

          break;

        case 'staff':
          debugPrint('CAMPUSFIX: Opening Staff Dashboard.');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const StaffDashboardPage()),
          );

          break;

        default:
          await _authService.logout();

          if (!mounted) return;

          _showMessage('Invalid account role.', Colors.red);
      }
    }
    // --------------------------------------------------
    // FIREBASE AUTHENTICATION ERRORS
    // --------------------------------------------------
    on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('CAMPUSFIX AUTH ERROR: ${e.code} - ${e.message}');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message =
              'Invalid login details. '
              'Check your email/USN and password.';
          break;

        case 'user-disabled':
          message =
              'This account has been disabled. '
              'Contact the administrator.';
          break;

        case 'too-many-requests':
          message =
              'Too many login attempts. '
              'Please try again later.';
          break;

        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;

        default:
          message = e.message ?? 'Authentication failed. Please try again.';
      }

      _showMessage(message, Colors.red);
    }
    // --------------------------------------------------
    // FIREBASE / FIRESTORE ERRORS
    // --------------------------------------------------
    on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'CAMPUSFIX FIREBASE ERROR: '
        '${e.plugin}/${e.code} - ${e.message}',
      );

      debugPrintStack(stackTrace: stackTrace);

      await _authService.logout();

      if (!mounted) return;

      final message = e.code == 'permission-denied'
          ? 'Access to your profile was denied. '
                'Check Firestore security rules.'
          : 'Could not load your profile: '
                '${e.message ?? e.code}';

      _showMessage(message, Colors.red);
    }
    // --------------------------------------------------
    // TIMEOUT ERROR
    // --------------------------------------------------
    on TimeoutException catch (e, stackTrace) {
      debugPrint('CAMPUSFIX TIMEOUT: $e');

      debugPrintStack(stackTrace: stackTrace);

      await _authService.logout();

      if (!mounted) return;

      _showMessage(
        'The server took too long to respond. '
        'Check your internet connection.',
        Colors.red,
      );
    }
    // --------------------------------------------------
    // GENERAL ERRORS
    // --------------------------------------------------
    catch (e, stackTrace) {
      debugPrint('CAMPUSFIX LOGIN ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      await _authService.logout();

      if (!mounted) return;

      _showMessage('Login failed: $e', Colors.red);
    }
    // --------------------------------------------------
    // RESET LOADING STATE
    // --------------------------------------------------
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        debugPrint('CAMPUSFIX: Login loading state cleared.');
      }
    }
  }

  // --------------------------------------------------
  // SHOW MESSAGE
  // --------------------------------------------------

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // --------------------------------------------------
  // FORGOT PASSWORD
  // --------------------------------------------------

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password recovery will be implemented later.'),
      ),
    );
  }

  // --------------------------------------------------
  // REGISTER
  // --------------------------------------------------

  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const RegisterPage()),
    );
  }

  // --------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(185, 234, 255, 243),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 850;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(flex: 6, child: _buildBrandingSection()),

                Expanded(flex: 4, child: _buildLoginSection()),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 504, child: _buildBrandingSection()),

                _buildLoginSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // LEFT BRANDING SECTION
  // --------------------------------------------------

  Widget _buildBrandingSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/college_background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF07519C), Color(0xFF1685CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                navy.withValues(alpha: 0.85),
                const Color(0xFF0759A0).withValues(alpha: 0.48),
                navy.withValues(alpha: 0.72),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        'assets/images/college_logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_balance,
                            size: 65,
                            color: navy,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Campus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Fix',
                            style: TextStyle(
                              color: yellow,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'REPORT   •   TRACK   •   RESOLVE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'A smarter campus for a better tomorrow',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),

                // FEATURE HIGHLIGHTS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: _FeatureItem(
                          icon: Icons.campaign_rounded,
                          title: 'Report',
                          subtitle: 'Issues',
                        ),
                      ),

                      Expanded(
                        child: _FeatureItem(
                          icon: Icons.assignment_rounded,
                          title: 'Track',
                          subtitle: 'Progress',
                        ),
                      ),

                      Expanded(
                        child: _FeatureItem(
                          icon: Icons.verified_rounded,
                          title: 'Faster',
                          subtitle: 'Resolution',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // RIGHT LOGIN SECTION
  // --------------------------------------------------

  Widget _buildLoginSection() {
    return Container(
      color: const Color(0xFFF6F9FF),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: navy.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADING

                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Login to CampusFix',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: Colors.blueGrey),
                    ),

                    const SizedBox(height: 30),

                    // ACCOUNT TYPE SELECTION
                    const Text(
                      'Select Account Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            icon: Icons.school_rounded,
                            title: 'Student',
                            subtitle: 'Report & Track',
                            color: const Color(0xFF0870CE),
                            background: const Color(0xFFEAF4FF),
                            selected: _selectedRole == 'student',
                            onTap: () {
                              setState(() {
                                _selectedRole = 'student';
                                _usnController.clear();
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _RoleCard(
                            icon: Icons.groups_rounded,
                            title: 'Coordinator',
                            subtitle: 'Manage & Assign',
                            color: const Color(0xFF00A5A9),
                            background: const Color(0xFFE8FAF4),
                            selected: _selectedRole == 'coordinator',
                            onTap: () {
                              setState(() {
                                _selectedRole = 'coordinator';
                                _usnController.clear();
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _RoleCard(
                            icon: Icons.engineering_rounded,
                            title: 'Maintenance',
                            subtitle: 'Resolve Issues',
                            color: const Color(0xFFF3B500),
                            background: const Color(0xFFFFF8E7),
                            selected: _selectedRole == 'staff',
                            onTap: () {
                              setState(() {
                                _selectedRole = 'staff';
                                _usnController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // DYNAMIC USERNAME / EMAIL FIELD
                    _buildInputField(
                      controller: _usnController,

                      hint: _selectedRole == 'student'
                          ? 'USN / CET Number'
                          : 'Email Address',

                      icon: Icons.person_outline,

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _selectedRole == 'student'
                              ? 'Please enter your USN or CET number'
                              : 'Please enter your email address';
                        }

                        if (_selectedRole != 'student' &&
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // PASSWORD FIELD
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,

                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 5),

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // LOGIN BUTTON
                    SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(width: 12),

                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // OR DIVIDER
                    const Row(
                      children: [
                        Expanded(child: Divider()),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ),

                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // REGISTRATION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'New to CampusFix? ',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: _register,
                          child: const Text(
                            'Register Here',
                            style: TextStyle(
                              color: blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CUSTOM INPUT FIELD
  // --------------------------------------------------

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(icon, color: Colors.blueGrey),

        suffixIcon: suffix,

        filled: true,
        fillColor: const Color(0xFFFBFCFF),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 19,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFDCE4F1)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFDCE4F1)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// FEATURE ITEM
// --------------------------------------------------

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE6F1FF),
          child: Icon(icon, color: const Color(0xFF0759A0), size: 28),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF092B65),
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// INTERACTIVE ROLE CARD
// --------------------------------------------------

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 17),

        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),

          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),

        child: Column(
          children: [
            Icon(icon, size: 37, color: color),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF092B65),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),

            if (selected) ...[
              const SizedBox(height: 5),

              Icon(Icons.check_circle, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
