import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/settlement_location.dart';
import 'package:mastera24/screens/auth/role_setup_screen.dart';
import 'package:mastera24/services/firestore_service.dart';
import 'package:mastera24/theme/app_theme.dart';

class _RecordingFirestoreService extends FirestoreService {
  String? uid;
  String? role;
  String? name;
  String? phone;
  SettlementLocation? settlement;

  @override
  Future<void> createUserProfile({
    required String uid,
    required String role,
    required String name,
    required String phone,
    required SettlementLocation settlement,
    String avatarUrl = '',
  }) async {
    this.uid = uid;
    this.role = role;
    this.name = name;
    this.phone = phone;
    this.settlement = settlement;
  }
}

const _testSettlement = SettlementLocation(
  city: 'Алматы',
  displayName: 'Алматы, Казахстан',
  region: 'Алматинская область',
  latitude: 43.238949,
  longitude: 76.889709,
  type: 'city',
);

void main() {
  testWidgets('shows default phone number', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const RoleSetupScreen(uid: 'user-1'),
      ),
    );

    expect(find.text('(777) 777-77-77'), findsOneWidget);
  });

  testWidgets('does not ask for phone again when initial phone is known', (
    tester,
  ) async {
    final firestoreService = _RecordingFirestoreService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RoleSetupScreen(
          uid: 'user-1',
          initialPhone: '+7 (705) 259-73-68',
          initialSettlement: _testSettlement,
          firestoreService: firestoreService,
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('+7 (705) 259-73-68'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Dana');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(firestoreService.phone, '+7 (705) 259-73-68');
  });

  testWidgets('shows validation messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const RoleSetupScreen(uid: 'user-1'),
      ),
    );

    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.tap(find.text('Продолжить'));
    await tester.pump();

    expect(find.text('Введите имя'), findsOneWidget);
    expect(
      find.text('Введите телефон в формате +7 (###) ###-##-##'),
      findsOneWidget,
    );
    expect(find.text('Укажите населенный пункт'), findsOneWidget);
  });

  testWidgets('saves formatted profile with selected role', (tester) async {
    final firestoreService = _RecordingFirestoreService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RoleSetupScreen(
          uid: 'user-1',
          initialSettlement: _testSettlement,
          firestoreService: firestoreService,
        ),
      ),
    );

    await tester.tap(find.text('Исполнитель'));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'Dana');
    await tester.enterText(
      find.byType(TextFormField).last,
      '+7 (777) 123-45-67',
    );
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(firestoreService.uid, 'user-1');
    expect(firestoreService.role, 'executor');
    expect(firestoreService.name, 'Dana');
    expect(firestoreService.phone, '+7 (777) 123-45-67');
    expect(firestoreService.settlement?.city, 'Алматы');
  });
}
