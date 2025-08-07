// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Getter for firestore service (for provider access)
  FirestoreService get firestoreService => _firestoreService;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      // Create user account
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);
        
        // Create user profile in Firestore
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
          isActive: true,
          role: UserRole.resident,
        );

        await _createUserProfile(userModel);
        
        // Send email verification
        await user.sendEmailVerification();
        
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Get user profile from Firestore
        final userModel = await _getUserProfile(user.uid);
        
        // Update last login time
        if (userModel != null) {
          await _updateLastLogin(user.uid);
        }
        
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw AuthException('Failed to send email verification: $e');
    }
  }

  /// Reload current user
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      throw AuthException('Failed to reload user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        
        // Update Firestore profile
        await _updateUserProfile(user.uid, {
          if (displayName != null) 'display_name': displayName,
          if (photoURL != null) 'photo_url': photoURL,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  /// Update user profile in Firestore with additional fields
  Future<void> updateUserProfileData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateUserProfile(uid, data);
    } catch (e) {
      throw AuthException('Failed to update user profile data: $e');
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Failed to update password: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user profile from Firestore
        await _deleteUserProfile(user.uid);
        
        // Delete Firebase Auth account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  /// Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Failed to re-authenticate: $e');
    }
  }

  /// Get user profile from Firestore
  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user != null) {
      return await _getUserProfile(user.uid);
    }
    return null;
  }

  /// Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods

  Future<void> _createUserProfile(UserModel userModel) async {
    try {
      await _firestoreService.createUserProfile(userModel);
    } catch (e) {
      debugPrint('Failed to create user profile in Firestore: $e');
      // Don't throw here as the auth account was created successfully
    }
  }

  Future<UserModel?> _getUserProfile(String uid) async {
    try {
      return await _firestoreService.getUserProfile(uid);
    } catch (e) {
      debugPrint('Failed to get user profile from Firestore: $e');
      return null;
    }
  }

  Future<void> _updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateUserProfile(uid, data);
    } catch (e) {
      debugPrint('Failed to update user profile in Firestore: $e');
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestoreService.updateUserProfile(uid, {
        'last_login': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to update last login: $e');
    }
  }

  Future<void> _deleteUserProfile(String uid) async {
    try {
      await _firestoreService.deleteUserProfile(uid);
    } catch (e) {
      debugPrint('Failed to delete user profile from Firestore: $e');
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'An authentication error occurred.';
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}