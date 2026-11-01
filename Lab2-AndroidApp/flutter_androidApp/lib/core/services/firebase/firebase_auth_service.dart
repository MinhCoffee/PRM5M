import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_profile.dart';
import '../google_sign_in_bootstrap.dart';
import 'firebase_evidence_logger.dart';

enum AuthFailureKind { cancelled, network, misconfigured, unknown }

/// Error with a message that is safe to show to the user.
class AuthException implements Exception {
  final AuthFailureKind kind;
  final String userMessage;
  final Object? cause;

  const AuthException(this.kind, this.userMessage, {this.cause});

  bool get isCancelled => kind == AuthFailureKind.cancelled;

  @override
  String toString() => 'AuthException($kind): $userMessage';
}

abstract interface class IAuthService {
  /// Signs in with Google and links it to Firebase Auth.
  /// Throws [AuthException]; never returns a made-up user.
  Future<UserProfile> signInWithGoogle();
  Future<void> signOut();
  UserProfile? get currentUser;
  Stream<UserProfile?> get authStateChanges;

  /// True only when Firebase Auth restored a real, persisted session.
  Future<bool> hasCachedSession();
}

class FirebaseAuthService implements IAuthService {
  UserProfile? _cachedUser;
  final _authController = StreamController<UserProfile?>.broadcast();

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

  UserProfile _toProfile(fb_auth.User user) {
    final email = user.email ?? '';
    return UserProfile(
      id: user.uid,
      displayName: (user.displayName?.isNotEmpty ?? false)
          ? user.displayName!
          : email,
      email: email,
      photoUrl: user.photoURL ?? '',
      lecturerCode: email.contains('@') ? email.split('@').first : '',
      authProvider: 'firebase_auth',
      isEmailVerified: user.emailVerified,
      lastSignInTime: user.metadata.lastSignInTime,
    );
  }

  @override
  Future<bool> hasCachedSession() async {
    if (!_isFirebaseReady) return false;
    try {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser == null) return false;
      _cachedUser = _toProfile(fbUser);
      _authController.add(_cachedUser);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    FirebaseEvidenceLogger.log(
      service: 'Authentication',
      action: 'Initiating Google Sign-In flow',
      payload: {'timestamp': DateTime.now().toIso8601String()},
    );

    if (!_isFirebaseReady) {
      const err = AuthException(
        AuthFailureKind.misconfigured,
        'Firebase chưa được khởi tạo. Kiểm tra google-services.json và '
        'khởi động lại ứng dụng.',
      );
      _logFailure(err);
      throw err;
    }

    try {
      await GoogleSignInBootstrap.ensureInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          AuthFailureKind.misconfigured,
          'Google không trả về idToken. Kiểm tra SHA-1/SHA-256 trong Firebase '
          'và GOOGLE_WEB_CLIENT_ID trong .env.',
        );
      }

      final credential = fb_auth.GoogleAuthProvider.credential(idToken: idToken);
      final userCredential =
          await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw const AuthException(
          AuthFailureKind.unknown,
          'Firebase không trả về người dùng sau khi đăng nhập.',
        );
      }

      final profile = _toProfile(fbUser);
      _cachedUser = profile;
      _authController.add(profile);

      FirebaseEvidenceLogger.log(
        service: 'Authentication',
        action: 'Google Sign-In Success',
        // uid only: no email / display name in logs.
        payload: {'uid': profile.id, 'provider': profile.authProvider},
        isSuccess: true,
      );
      return profile;
    } on AuthException catch (e) {
      _logFailure(e);
      rethrow;
    } on GoogleSignInException catch (e) {
      final err = e.code == GoogleSignInExceptionCode.canceled
          ? AuthException(
              AuthFailureKind.cancelled,
              'Bạn đã hủy đăng nhập Google. Nhấn "Đăng nhập" để thử lại.',
              cause: e,
            )
          : AuthException(
              AuthFailureKind.unknown,
              'Đăng nhập Google thất bại (${e.code.name}).',
              cause: e,
            );
      _logFailure(err);
      throw err;
    } on fb_auth.FirebaseAuthException catch (e) {
      final err = e.code == 'network-request-failed'
          ? AuthException(
              AuthFailureKind.network,
              'Mất kết nối mạng. Kiểm tra Wi-Fi/4G rồi thử lại.',
              cause: e,
            )
          : AuthException(
              AuthFailureKind.unknown,
              'Firebase từ chối đăng nhập (${e.code}).',
              cause: e,
            );
      _logFailure(err);
      throw err;
    } catch (e) {
      final err = AuthException(
        AuthFailureKind.unknown,
        'Đăng nhập thất bại: $e',
        cause: e,
      );
      _logFailure(err);
      throw err;
    }
  }

  void _logFailure(AuthException e) {
    FirebaseEvidenceLogger.log(
      service: 'Authentication',
      action: 'Google Sign-In Failed (${e.kind.name})',
      payload: {'kind': e.kind.name},
      isSuccess: false,
      errorMessage: e.userMessage,
    );
    debugPrint('Sign in failed: ${e.kind.name} ${e.cause ?? ''}');
  }

  @override
  Future<void> signOut() async {
    FirebaseEvidenceLogger.log(
      service: 'Authentication',
      action: 'Signing out',
      payload: {'uid': _cachedUser?.id ?? 'unknown'},
    );

    try {
      if (_isFirebaseReady) {
        await fb_auth.FirebaseAuth.instance.signOut();
      }
      await GoogleSignInBootstrap.ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('SignOut exception: $e');
    } finally {
      _cachedUser = null;
      _authController.add(null);
    }
  }
}
