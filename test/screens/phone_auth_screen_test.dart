import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/screens/auth/phone_auth_screen.dart';
import 'package:mastera24/services/auth_service.dart';
import 'package:mastera24/theme/app_theme.dart';

class _FakeUserCredential implements UserCredential {
  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;

  @override
  User? get user => null;
}

class _RecordingAuthService extends AuthService {
  Object? error;
  String? lastPhone;
  String? lastPassword;
  bool loginCalled = false;
  bool registerCalled = false;
  bool resetCalled = false;

  @override
  Future<UserCredential> signInWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) async {
    loginCalled = true;
    lastPhone = phoneNumber;
    lastPassword = password;
    if (error != null) {
      throw error!;
    }
    return _FakeUserCredential();
  }

  @override
  Future<UserCredential> registerWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) async {
    registerCalled = true;
    lastPhone = phoneNumber;
    lastPassword = password;
    if (error != null) {
      throw error!;
    }
    return _FakeUserCredential();
  }

  @override
  Future<void> resetPhonePassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    resetCalled = true;
    lastPhone = phoneNumber;
    lastPassword = newPassword;
    if (error != null) {
      throw error!;
    }
  }
}

void main() {
  testWidgets('shows default phone number', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PhoneAuthScreen()),
    );

    expect(find.text('(777) 777-77-77'), findsOneWidget);
  });

  testWidgets('shows validation error for invalid phone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PhoneAuthScreen()),
    );

    await tester.enterText(find.byType(TextField).first, '+7');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Войти'));
    await tester.pump();

    expect(
      find.text('Введите номер в формате +7 (###) ###-##-##.'),
      findsOneWidget,
    );
  });

  testWidgets('toggles between login and registration modes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PhoneAuthScreen()),
    );

    await tester.tap(find.text('Нет аккаунта? Регистрация'));
    await tester.pump();

    expect(find.text('Зарегистрироваться'), findsOneWidget);
    expect(find.text('Уже есть аккаунт? Войти'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PhoneAuthScreen()),
    );

    TextField passwordField() {
      return tester.widget<TextField>(find.widgetWithText(TextField, 'Пароль'));
    }

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('toggles reset password visibility', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PhoneAuthScreen()),
    );

    await tester.tap(find.text('Забыли пароль? Восстановить'));
    await tester.pumpAndSettle();

    TextField newPasswordField() {
      return tester.widget<TextField>(
        find.widgetWithText(TextField, 'Новый пароль'),
      );
    }

    expect(newPasswordField().obscureText, isTrue);
    final showPasswordButton = tester.widget<IconButton>(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(IconButton),
          )
          .first,
    );
    showPasswordButton.onPressed!();
    await tester.pump();
    expect(newPasswordField().obscureText, isFalse);
  });

  testWidgets('submits registration with injected auth service', (
    tester,
  ) async {
    final authService = _RecordingAuthService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PhoneAuthScreen(authService: authService),
      ),
    );

    await tester.tap(find.text('Нет аккаунта? Регистрация'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '+7 (777) 123-45-67');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();

    expect(authService.registerCalled, isTrue);
    expect(authService.lastPhone, '(777) 123-45-67');
    expect(authService.lastPassword, '123456');
  });

  testWidgets('shows mapped backend error on login', (tester) async {
    final authService = _RecordingAuthService()
      ..error = FirebaseAuthException(code: 'user-not-found');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PhoneAuthScreen(authService: authService),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '+7 (777) 123-45-67');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Аккаунт с таким номером не найден.'), findsOneWidget);
  });

  testWidgets('resets password from forgot password dialog', (tester) async {
    final authService = _RecordingAuthService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PhoneAuthScreen(authService: authService),
      ),
    );

    await tester.tap(find.text('Забыли пароль? Восстановить'));
    await tester.pumpAndSettle();

    expect(find.text('Восстановление пароля'), findsOneWidget);

    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), '+7 (777) 123-45-67');
    await tester.enterText(dialogFields.at(1), '654321');
    await tester.enterText(dialogFields.at(2), '654321');
    await tester.tap(find.text('Сменить пароль'));
    await tester.pumpAndSettle();

    expect(authService.resetCalled, isTrue);
    expect(authService.lastPhone, '(777) 123-45-67');
    expect(authService.lastPassword, '654321');
    expect(find.text('Пароль обновлен. Теперь можно войти.'), findsOneWidget);
  });
}
