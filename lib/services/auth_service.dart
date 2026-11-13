import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate internal Firebase identifier for students.
  String _generateInternalEmail(String identifier) {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    return '$normalizedIdentifier@auth.campusfix.invalid';
  }

  // STUDENT REGISTRATION
  Future<UserCredential> registerStudent({
    required String name,
    required String identifier,
    required String password,
    required String department,
    required String year,
    String? cetNumber,
    String? usn,
  }) async {
    try {
      final internalEmail = _generateInternalEmail(identifier);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );

      final uid = credential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'cetNumber': cetNumber?.trim(),
        'usn': usn?.trim(),
        'loginIdentifier': identifier.trim().toUpperCase(),
        'department': department,
        'year': year,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Student registration failed: $e');
    }
  }

  // STUDENT LOGIN
  Future<UserCredential> loginStudent({
    required String identifier,
    required String password,
  }) async {
    try {
      final internalEmail = _generateInternalEmail(identifier);

      final credential = await _auth.signInWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );

      await _verifyRole('student');

      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // COORDINATOR LOGIN
  Future<UserCredential> loginCoordinator({
    required String email,
    required String password,
  }) async {
    return _loginWithRole(
      email: email,
      password: password,
      expectedRole: 'coordinator',
    );
  }

  // MAINTENANCE STAFF LOGIN
  Future<UserCredential> loginStaff({
    required String email,
    required String password,
  }) async {
    return _loginWithRole(
      email: email,
      password: password,
      expectedRole: 'staff',
    );
  }

  // COMMON EMAIL LOGIN WITH ROLE VERIFICATION
  Future<UserCredential> _loginWithRole({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      await _verifyRole(expectedRole);

      return credential;
    } catch (e) {
      // Do not leave an incorrectly authenticated account signed in.
      await _auth.signOut();
      rethrow;
    }
  }

  // VERIFY USER ROLE FROM FIRESTORE
  Future<void> _verifyRole(String expectedRole) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User authentication failed.');
    }

    final profile = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!profile.exists) {
      throw Exception('User profile not found.');
    }

    final role = profile.data()?['role'];

    if (role != expectedRole) {
      throw Exception(
        'Access denied. This account is not registered as $expectedRole.',
      );
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // CURRENT USER
  User? get currentUser => _auth.currentUser;

  // GET USER PROFILE
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile({
    String? uid,
  }) async {
    final userId = uid ?? _auth.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user found.');
    }

    return await _firestore.collection('users').doc(userId).get();
  }
}