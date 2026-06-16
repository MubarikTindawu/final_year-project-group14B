import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Track if Firebase has finished its initial check to prevent Splash Screen hangs
  bool _isInitialCheckDone = false;
  bool get isInitialCheckDone => _isInitialCheckDone;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialCheckDone = true;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // REGISTER
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password
      );

      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'firstName': firstName,
          'lastName': lastName,
          'email': email.trim(),
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'farmer',
        });
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint("Registration Error: $e");
      throw "An unexpected error occurred. Please try again.";
    } finally {
      _setLoading(false);
    }
  }

  // LOGIN
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // FORGOT PASSWORD
  Future<void> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  // THE FIX: Mapping Firebase Errors to User-Friendly Messages
  String _handleAuthError(FirebaseAuthException e) {
    // Helpful for debugging in the terminal
    debugPrint("Firebase Error Code: ${e.code}");

    switch (e.code) {
    // Modern Firebase versions use this for both wrong email and wrong password
      case 'invalid-credential':
        return "Incorrect email or password.";
      case 'user-not-found':
        return "No user found with this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'invalid-email':
        return "The email address is not valid.";
      case 'weak-password':
        return "The password is too weak.";
      case 'network-request-failed':
        return "Please check your internet connection.";
      case 'too-many-requests':
        return "Too many attempts. Try again later.";
      default:
        return "Authentication failed. Please try again.";
    }
  }
}