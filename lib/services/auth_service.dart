import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Enhanced with better error handling
  Future<User?> register(String email, String password, String username) async {
    try {
      print("AuthService: Registering with email: $email, username: $username");
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("AuthService: Registration successful for UID: ${credential.user?.uid}");

      // Added error handling for display name update
      try {
        await credential.user?.updateDisplayName(username);
        print("AuthService: Username updated to: $username");
      } catch (e) {
        print("AuthService: Warning - Failed to update display name: $e");
        // Continue anyway since the account was created
      }

      return credential.user;
    } catch (e) {
      print("AuthService: Registration error: $e");
      rethrow;
    }
  }

  // Enhanced login with better error handling
  Future<User?> login(String email, String password) async {
    try {
      print("AuthService: Logging in with email: $email");

      // Using a timeout to prevent hanging
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException("Login timed out. Please check your internet connection.");
      });

      print("AuthService: Login successful for UID: ${credential.user?.uid}");
      print("AuthService: User display name: ${credential.user?.displayName}");
      print("AuthService: Email verified: ${credential.user?.emailVerified}");
      return credential.user;
    } catch (e) {
      print("AuthService: Login error: $e");
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      print("AuthService: Resetting password for email: $email");
      await _auth.sendPasswordResetEmail(email: email);
      print("AuthService: Password reset email sent successfully");
    } catch (e) {
      print("AuthService: Password reset error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      print("AuthService: Logging out current user");
      await _auth.signOut();
      print("AuthService: Logout successful");
    } catch (e) {
      print("AuthService: Logout error: $e");
      rethrow;
    }
  }

  User? get currentUser {
    final user = _auth.currentUser;
    print("AuthService: Current user requested, UID: ${user?.uid}");
    return user;
  }

  // Added method to check auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}