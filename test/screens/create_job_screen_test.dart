import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/app_catalogs.dart';
import 'package:mastera24/models/job.dart';
import 'package:mastera24/models/settlement_location.dart';
import 'package:mastera24/screens/customer/create_job_screen.dart';
import 'package:mastera24/services/firestore_service.dart';
import 'package:mastera24/theme/app_theme.dart';

class _RecordingFirestoreService extends FirestoreService {
  String? title;
  String? description;
  String? category;
  String? city;
  int? budget;
  int? bidFeeKzt;
  String? customerId;
  String? ownerRole;
  String? serviceCategory;
  String? updatedJobId;
  DateTime? scheduledAt;

  @override
  Future<AppCatalogs> getAppCatalogs() async {
    return const AppCatalogs(
      categories: [
        ServiceCategory(id: 'repair', name: 'Ремонт', bidFeeKzt: 300),
        ServiceCategory(id: 'cleaning', name: 'Клининг', bidFeeKzt: 200),
      ],
      cities: ['Алматы', 'Астана'],
    );
  }

  @override
  Future<String> createJob({
    required String title,
    required String description,
    required String category,
    required SettlementLocation settlement,
    required DateTime scheduledAt,
    required int budget,
    required int bidFeeKzt,
    required String customerId,
    String ownerRole = 'customer',
  }) async {
    this.title = title;
    this.description = description;
    this.category = category;
    city = settlement.city;
    this.scheduledAt = scheduledAt;
    this.budget = budget;
    this.bidFeeKzt = bidFeeKzt;
    this.customerId = customerId;
    this.ownerRole = ownerRole;
    return 'job-1';
  }

  @override
  Future<void> addUserServiceCategory({
    required String uid,
    required String category,
  }) async {
    serviceCategory = category;
  }

  @override
  Future<void> updateJob({
    required String jobId,
    required String title,
    required String description,
    required String category,
    required SettlementLocation settlement,
    required DateTime scheduledAt,
    required int budget,
    required int bidFeeKzt,
  }) async {
    updatedJobId = jobId;
    this.title = title;
    this.description = description;
    this.category = category;
    city = settlement.city;
    this.scheduledAt = scheduledAt;
    this.budget = budget;
    this.bidFeeKzt = bidFeeKzt;
  }
}

const _jobSettlement = SettlementLocation(
  city: 'Алматы',
  displayName: 'Алматы, Казахстан',
  region: 'Алматинская область',
  latitude: 43.238949,
  longitude: 76.889709,
  type: 'city',
);

final _existingJob = Job(
  id: 'job-99',
  title: 'Старый заказ',
  description: 'Старое описание',
  category: 'Ремонт',
  city: 'Алматы',
  cityRegion: 'Алматинская область',
  budget: 7000,
  bidFeeKzt: 300,
  customerId: 'user-1',
  status: 'open',
  scheduledAt: DateTime(2025, 2, 10),
  createdAt: DateTime(2025, 1, 1),
);

Widget _wrapCreateJobScreen({
  required FirestoreService firestoreService,
  Job? existingJob,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('ru'), Locale('en')],
    home: CreateJobScreen(
      firestoreService: firestoreService,
      currentUserId: 'user-1',
      initialSettlement: _jobSettlement,
      existingJob: existingJob,
    ),
  );
}

void main() {
  testWidgets('shows validation errors for blank fields', (tester) async {
    await tester.pumpWidget(
      _wrapCreateJobScreen(firestoreService: _RecordingFirestoreService()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Создать заказ'));
    await tester.tap(find.text('Создать заказ'));
    await tester.pump();

    expect(find.text('Заполните описание'), findsOneWidget);
    expect(find.text('Введите бюджет'), findsOneWidget);
  });

  testWidgets('creates job with trimmed values', (tester) async {
    final firestoreService = _RecordingFirestoreService();

    await tester.pumpWidget(
      _wrapCreateJobScreen(firestoreService: firestoreService),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  Срочно нужен мастер ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '12000');

    await tester.ensureVisible(find.text('Создать заказ'));
    await tester.tap(find.text('Создать заказ'));
    await tester.pumpAndSettle();

    expect(firestoreService.title, 'Ремонт');
    expect(firestoreService.description, 'Срочно нужен мастер');
    expect(firestoreService.category, 'Ремонт');
    expect(firestoreService.city, 'Алматы');
    expect(firestoreService.scheduledAt, isNotNull);
    expect(firestoreService.budget, 12000);
    expect(firestoreService.bidFeeKzt, 300);
    expect(firestoreService.customerId, 'user-1');
  });

  testWidgets('updates existing job with trimmed values', (tester) async {
    final firestoreService = _RecordingFirestoreService();

    await tester.pumpWidget(
      _wrapCreateJobScreen(
        firestoreService: firestoreService,
        existingJob: _existingJob,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Редактировать заказ'), findsOneWidget);
    expect(find.text('Сохранить изменения'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  Новое описание ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '18000');

    await tester.ensureVisible(find.text('Сохранить изменения'));
    await tester.tap(find.text('Сохранить изменения'));
    await tester.pumpAndSettle();

    expect(firestoreService.updatedJobId, 'job-99');
    expect(firestoreService.title, 'Ремонт');
    expect(firestoreService.description, 'Новое описание');
    expect(firestoreService.category, 'Ремонт');
    expect(firestoreService.city, 'Алматы');
    expect(firestoreService.scheduledAt, DateTime(2025, 2, 10));
    expect(firestoreService.budget, 18000);
    expect(firestoreService.bidFeeKzt, 300);
  });

  testWidgets('opens calendar when tapping scheduled date field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapCreateJobScreen(firestoreService: _RecordingFirestoreService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scheduledDateField')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
