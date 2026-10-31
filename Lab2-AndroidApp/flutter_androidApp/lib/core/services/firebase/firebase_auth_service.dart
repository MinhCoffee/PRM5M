import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_profile.dart';
import 'firebase_evidence_logger.dart';

abstract interface class IAuthService {
  Future<UserProfile?> signInWithGoogle();
  Future<void> signOut();
  UserProfile? get currentUser;
  Stream<UserProfile?> get authStateChanges;
  Future<bool> hasCachedSession();
}

class FirebaseAuthService implements IAuthService {
  final GoogleSignIn _googleSignIn;
  UserProfile? _cachedUser;
  final _authController = StreamController<UserProfile?>.broadcast();

  FirebaseAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  UserProfile? get currentUser => _cachedUser;

  @override
  Stream<UserProfile?> get authStateChanges => _authController.stream;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasCachedSession() async {
    try {
      if (_isFirebaseReady) {
        final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          _cachedUser = UserProfile(
            id: fbUser.uid,
            displayName: fbUser.displayName ?? 'Giảng viên FPT',
            email: fbUser.email ?? 'lecturer@fpt.edu.vn',
            photoUrl: fbUser.photoURL ?? '',
            authProvider: 'firebase_auth',
            isEmailVerified: fbUser.emailVerified,
            lastSignInTime: fbUser.metadata.lastSignInTime,
          );
          _authController.add(_cachedUser);
          return true;
        }
      }
      return _cachedUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserProfile?> signInWithGoogle() async {
    FirebaseEvidenceLogger.log(
      service: 'Authentication',
      action: 'Initiating Google Sign-In flow',
      payload: {'timestamp': DateTime.now().toIso8601String()},
    );

    try {
      // 1. Authenticate with Google
      final googleUser = await _googleSignIn.authenticate();
      final email = googleUser.email;
      final displayName = googleUser.displayName ?? 'Dr. Nguyen Van Minh';
      final photoUrl = googleUser.photoUrl ?? '';
      final googleId = googleUser.id;

      UserProfile userProfile;

      // 2. If Firebase is active, sign in to Firebase Auth with Google OAuth credential
      if (_isFirebaseReady) {
        try {
          String? idToken;
          String? token;

          try {
            final googleAuth = await googleUser.authentication;
            idToken = googleAuth.idToken;
            token = googleAuth.accessToken;
          } catch (_) {}

          if (token == null) {
            final authorization = await googleUser.authorizationClient.authorizationForScopes([
              'email',
              'https://www.googleapis.com/auth/userinfo.profile',
            ]);
            token = authorization?.accessToken;
          }

          if (token != null || idToken != null) {
            final credential = fb_auth.GoogleAuthProvider.credential(
              accessToken: token,
              idToken: idToken,
            );
            final userCredential =
                await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
            final fbUser = userCredential.user;
            userProfile = UserProfile(
              id: fbUser?.uid ?? googleId,
              displayName: fbUser?.displayName ?? displayName,
              email: fbUser?.email ?? email,
              photoUrl: fbUser?.photoURL ?? photoUrl,
              authProvider: 'firebase_auth',
              isEmailVerified: fbUser?.emailVerified ?? true,
              lastSignInTime: fbUser?.metadata.lastSignInTime ?? DateTime.now(),
            );
          } else {
            userProfile = UserProfile.defaultLecturer(
              email: email,
              name: displayName,
              photoUrl: photoUrl,
              id: googleId,
            );
          }
        } catch (e) {
          debugPrint('FirebaseAuth link error, falling back to Google account: $e');
          userProfile = UserProfile.defaultLecturer(
            email: email,
            name: displayName,
            photoUrl: photoUrl,
            id: googleId,
          );
        }
      } else {
        userProfile = UserProfile.defaultLecturer(
          email: email,
          name: displayName,
          photoUrl: photoUrl,
          id: googleId,
        );
      }

      _cachedUser = userProfile;
      _authController.add(_cachedUser);

      FirebaseEvidenceLogger.log(
        service: 'Authentication',
        action: 'Google Sign-In Success',
        payload: {
          'uid': userProfile.id,
          'email': userProfile.email,
          'displayName': userProfile.displayName,
          'provider': userProfile.authProvider,
        },
        isSuccess: true,
      );

      return _cachedUser;
    } catch (e, st) {
      FirebaseEvidenceLogger.log(
        service: 'Authentication',
        action: 'Google Sign-In Failed',
        payload: {'error': e.toString()},
        isSuccess: false,
        errorMessage: e.toString(),
      );
      debugPrint('Sign in error: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    FirebaseEvidenceLogger.log(
      service: 'Authentication',
      action: 'Signing out',
      payload: {'email': _cachedUser?.email ?? 'unknown'},
    );

    try {
      if (_isFirebaseReady) {
        await fb_auth.FirebaseAuth.instance.signOut();
      }
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('SignOut exception: $e');
    } finally {
      _cachedUser = null;
      _authController.add(null);
    }
  }
}
