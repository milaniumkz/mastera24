import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/job.dart';
import 'package:mastera24/theme/app_theme.dart';
import 'package:mastera24/widgets/job_card.dart';
import 'package:mastera24/widgets/loading_view.dart';

void main() {
  testWidgets('LoadingView shows spinner and custom message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoadingView(message: 'Ждём...'),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Ждём...'), findsOneWidget);
  });

  testWidgets('JobCard renders data and handles tap', (tester) async {
    var tapped = false;
    final job = Job(
      id: 'job-1',
      title: 'Починить розетку',
      description: 'Нужен быстрый ремонт в квартире',
      category: 'Ремонт',
      city: 'Алматы',
      cityRegion: 'Алматинская область',
      budget: 5000,
      bidFeeKzt: 300,
      customerId: 'customer-1',
      status: 'open',
      scheduledAt: DateTime(2025, 1, 3),
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: JobCard(job: job, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Починить розетку'), findsOneWidget);
    expect(find.text('Ремонт'), findsOneWidget);
    expect(find.text('Алматы'), findsOneWidget);
    expect(find.text('03.01.2025'), findsOneWidget);
    expect(find.text('5000 KZT'), findsOneWidget);

    await tester.tap(find.byType(JobCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('JobCard shows bid count badge', (tester) async {
    final job = Job(
      id: 'job-1',
      title: 'Ремонт',
      description: 'Нужен быстрый ремонт в квартире',
      category: 'Ремонт',
      city: 'Алматы',
      cityRegion: 'Алматинская область',
      budget: 5000,
      bidFeeKzt: 300,
      customerId: 'customer-1',
      status: 'open',
      scheduledAt: DateTime(2025, 1, 3),
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: JobCard(job: job, bidCount: 2, onTap: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('JobCard bid badge handles tap separately', (tester) async {
    var cardTapped = false;
    var badgeTapped = false;
    final job = Job(
      id: 'job-1',
      title: 'Ремонт',
      description: 'Нужен быстрый ремонт в квартире',
      category: 'Ремонт',
      city: 'Алматы',
      cityRegion: 'Алматинская область',
      budget: 5000,
      bidFeeKzt: 300,
      customerId: 'customer-1',
      status: 'open',
      scheduledAt: DateTime(2025, 1, 3),
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: JobCard(
            job: job,
            bidCount: 2,
            onTap: () => cardTapped = true,
            onBidTap: () => badgeTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.mark_email_unread_outlined));
    await tester.pump();

    expect(badgeTapped, isTrue);
    expect(cardTapped, isFalse);
  });
}
