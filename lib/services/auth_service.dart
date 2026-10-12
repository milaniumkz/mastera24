import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/app_config.dart';
import '../utils/phone_utils.dart';

class AuthService {
  static bool _googleInitialized = false;
  static const String _primaryPhoneDomain = 'mastera42.kz';
  static const String _legacyPhoneDomain = 'mastera24.app';

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  bool get isGoogleSignInAvailable {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppConfig.isGoogleSignInConfigured;
    }
    return true;
  }

  bool get isAppleSignInAvailable {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  String _phoneToEmail(
    String phoneNumber, {
    String domain = _primaryPhoneDomain,
  }) {
    final normalized = PhoneUtils.normalize(phoneNumber);
    return 'phone_$normalized@$domain';
  }

  List<String> _phoneEmails(String phoneNumber) {
    return [
      _phoneToEmail(phoneNumber, domain: _primaryPhoneDomain),
      _phoneToEmail(phoneNumber, domain: _legacyPhoneDomain),
    ];
  }

  Future<UserCredential> signInWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) async {
    FirebaseAuthException? lastError;
    for (final email in _phoneEmails(phoneNumber)) {
      try {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        lastError = error;
        if (error.code != 'user-not-found' &&
            error.code != 'invalid-credential' &&
            error.code != 'invalid-login-credentials') {
          rethrow;
        }
      }
    }
    throw lastError ??
        FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found for the provided phone number.',
        );
  }

  Future<UserCredential> registerWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: _phoneToEmail(phoneNumber, domain: _primaryPhoneDomain),
      password: password,
    );
  }

  Future<void> resetPhonePassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    final callable = _functions.httpsCallable('resetPhonePassword');
    await callable.call({
      'phoneNumber': PhoneUtils.format(phoneNumber),
      'newPassword': newPassword,
    });
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signInWithGoogle() async {
    if (!isGoogleSignInAvailable) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Google вход пока не настроен для этой сборки.',
      );
    }

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        AppConfig.googleServerClientId.isEmpty) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Google вход пока не настроен для Android.',
      );
    }

    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      );
      _googleInitialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final auth = account.authentication;
    if (auth.idToken == null || auth.idToken!.isEmpty) {
      throw Exception('Google ID token не получен.');
    }
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    if (!isAppleSignInAvailable) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Apple вход доступен только на iOS.',
      );
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );

    return _auth.signInWithCredential(oauthCredential);
  }
}
