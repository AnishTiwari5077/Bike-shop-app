import 'package:bike_shop/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;

  String get displayName => _user?.displayName ?? 'Guest';
  String get email => _user?.email ?? '';
  String get photoUrl => _user?.photoURL ?? '';

  AuthProvider() {
    /// 🔥 FIXED: authStateChanges now exists
    AuthService.instance.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await AuthService.instance.signInWithGoogle();

      _user = user;

      notifyListeners();

      return user != null;
    } catch (e) {
      debugPrint('Provider sign-in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await AuthService.instance.signOut();

      _user = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Provider sign-out error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
