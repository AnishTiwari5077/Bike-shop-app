// lib/providers/auth_viewmodel.dart
// ---------------------------------------------------------------------------
// AuthViewModel — migrated from AuthProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/auth_viewmodel.dart'
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - Uses setLoading()/setSuccess()/setError()/setIdle() from base class
//   - Firebase auth stream listener preserved exactly
//   - signInWithGoogle() and signOut() methods preserved exactly
// ---------------------------------------------------------------------------

import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ViewModel managing Firebase authentication state.
///
/// Listens to the Firebase auth stream so the app reacts instantly to sign-in
/// and sign-out events from any source (Google, email, etc.).
/// Consumed by ProfileScreen, HomeScreen, CheckoutScreen.
class AuthViewModel extends BaseViewModel {
  User? _user;

  // ── Getters ───────────────────────────────────────────────────────────────

  User? get user => _user;
  bool get isSignedIn => _user != null;

  String get displayName => _user?.displayName ?? 'Guest';
  String get email => _user?.email ?? '';
  String get photoUrl => _user?.photoURL ?? '';

  // ── Constructor ───────────────────────────────────────────────────────────

  AuthViewModel() {
    // Listen to Firebase auth state changes and update _user automatically.
    AuthService.instance.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Google Sign-In via [AuthService].
  /// Returns `true` on success, `false` on failure.
  Future<bool> signInWithGoogle() async {
    try {
      setLoading();

      final user = await AuthService.instance.signInWithGoogle();
      _user = user;

      if (user != null) {
        setSuccess();
        return true;
      } else {
        setIdle();
        return false;
      }
    } catch (e) {
      debugPrint('AuthViewModel sign-in error: $e');
      setError('Sign-in failed. Please try again.');
      return false;
    }
  }

  /// Sign out from Firebase and Google.
  Future<void> signOut() async {
    try {
      setLoading();
      await AuthService.instance.signOut();
      _user = null;
      setIdle();
    } catch (e) {
      debugPrint('AuthViewModel sign-out error: $e');
      setIdle(); // Don't block UI on sign-out errors
    }
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef AuthProvider = AuthViewModel;
