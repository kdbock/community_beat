// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUser?.uid;

  /// Initialize auth provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      // Listen to auth state changes
      _authService.authStateChanges.listen(_onAuthStateChanged);
      
      // Get current user if signed in
      if (_authService.isSignedIn) {
        _currentUser = await _authService.getCurrentUserProfile();
      }
      
      _isInitialized = true;
      _clearError();
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );

      if (user != null) {
        _currentUser = user;
        _clearError();
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Sign up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        _clearError();
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _clearError();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to send password reset email: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to send email verification: $e');
      return false;
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      _currentUser = await _authService.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      _setError('Failed to reload user: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? address,
    List<String>? interests,
    Map<String, dynamic>? preferences,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      // Update Firebase Auth profile
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Update Firestore profile
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (photoURL != null) updates['photo_url'] = photoURL;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (interests != null) updates['interests'] = interests;
      if (preferences != null) updates['preferences'] = preferences;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _authService.updateUserProfileData(_currentUser!.uid, updates);

      // Update local user data
      _currentUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        photoURL: photoURL ?? _currentUser!.photoURL,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        address: address ?? _currentUser!.address,
        interests: interests ?? _currentUser!.interests,
        preferences: preferences ?? _currentUser!.preferences,
        updatedAt: DateTime.now(),
      );

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      // Re-authenticate first
      await _authService.reauthenticateWithPassword(currentPassword);
      
      // Update password
      await _authService.updatePassword(newPassword);
      
      _clearError();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete account
  Future<bool> deleteAccount(String password) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      // Re-authenticate first
      await _authService.reauthenticateWithPassword(password);
      
      // Delete account
      await _authService.deleteAccount();
      
      _currentUser = null;
      _clearError();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to delete account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      return await _authService.isEmailAvailable(email);
    } catch (e) {
      return false;
    }
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  Map<String, bool> validatePassword(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasDigits': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  /// Check if password is strong
  bool isStrongPassword(String password) {
    final validation = validatePassword(password);
    return validation.values.every((isValid) => isValid);
  }

  // Private methods

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      // User signed in
      try {
        _currentUser = await _authService.getCurrentUserProfile();
      } catch (e) {
        debugPrint('Failed to get user profile: $e');
        _currentUser = null;
      }
    } else {
      // User signed out
      _currentUser = null;
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Check if user has specific role
  bool hasRole(UserRole role) {
    return _currentUser?.role == role;
  }

  /// Check if user can perform admin actions
  bool get canPerformAdminActions => _currentUser?.isAdmin ?? false;

  /// Check if user can moderate content
  bool get canModerateContent => _currentUser?.canModerateContent ?? false;

  /// Check if user can create business listings
  bool get canCreateBusiness => _currentUser?.canCreateBusiness ?? false;


}