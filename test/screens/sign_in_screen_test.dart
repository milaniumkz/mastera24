import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/screens/auth/phone_auth_screen.dart';
import 'package:mastera24/screens/auth/sign_in_screen.dart';
import 'package:mastera24/services/auth_service.dart';
import 'package:mastera24/theme/app_theme.dart';

class _GoogleFailingAuthService extends AuthService {
  @override
  Future<UserCredential> signInWithGoogle() {
    return Future<UserCredential>.error(
      FirebaseAuthException(code: 'operation-not-allowed'),
    );
  }
}

void main() {
  testWidgets('navigates to phone auth screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const SignInScreen(),
      ),
    );

    await tester.tap(find.text('Войти по номеру телефона'));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneAuthScreen), findsOneWidget);
  });

  testWidgets(
    'shows mapped Google sign-in error',
    (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SignInScreen(authService: _GoogleFailingAuthService()),
      ),
    );

    await tester.tap(find.text('Войти через Google'));
    await tester.pumpAndSettle();

    expect(find.text('Способ входа пока не подключен.'), findsOneWidget);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );
}
