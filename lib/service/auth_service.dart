import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Google Sign-In v7 (NO constructor error)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  /// 🔥 Firebase auth stream (FIXED ERROR)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Initialize Google Sign-In (IMPORTANT for v7)
  Future<void> _initGoogle() async {
    if (_initialized) return;

    await _googleSignIn.initialize(
      serverClientId:
          "1007440937952-e6uqk7i6h2dq3em8ptvd77h0eshmdepf.apps.googleusercontent.com",
    );

    _initialized = true;

    debugPrint("Google Sign-In initialized");
  }

  /// 🔥 GOOGLE SIGN-IN (WORKING v7)
  Future<User?> signInWithGoogle() async {
    try {
      await _initGoogle();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final authClient = _googleSignIn.authorizationClient;

      final authorization = await authClient.authorizeScopes([
        'email',
        'profile',
      ]);

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
