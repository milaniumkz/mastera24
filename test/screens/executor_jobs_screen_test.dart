import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/job.dart';
import 'package:mastera24/models/settlement_location.dart';
import 'package:mastera24/screens/executor/executor_jobs_screen.dart';

void main() {
  Job buildJob({
    required String id,
    required String city,
    required String region,
    required String customerId,
    double lat = 0,
    double lon = 0,
    String ownerRole = 'customer',
    String status = 'open',
  }) {
    return Job(
      id: id,
      title: 'A',
      description: 'A',
      category: 'Ремонт',
      city: city,
      cityRegion: region,
      cityLat: lat,
      cityLon: lon,
      budget: 1000,
      bidFeeKzt: 300,
      customerId: customerId,
      ownerRole: ownerRole,
      status: status,
      scheduledAt: DateTime(2025, 1, 10),
      createdAt: DateTime(2025, 1, 1),
    );
  }

  const pavlodar = SettlementLocation(
    city: 'Павлодар',
    displayName: 'Павлодар',
    region: 'Павлодарская область',
    latitude: 52.287,
    longitude: 76.967,
    type: 'city',
  );

  test(
    'filterAvailableExecutorJobs keeps customer jobs and hides other cities',
    () {
      final filtered = filterAvailableExecutorJobs(
        [
          buildJob(
            id: 'own-customer-role',
            city: 'Павлодар',
            region: 'Павлодарская область',
            customerId: 'executor-1',
          ),
          buildJob(
            id: 'same-city',
            city: 'Павлодар',
            region: 'Павлодарская область',
            customerId: 'customer-1',
          ),
          buildJob(
            id: 'other-city',
            city: 'Алматы',
            region: 'Алматинская область',
            customerId: 'customer-2',
          ),
        ],
        currentUserId: 'executor-1',
        executorUserIds: {'executor-1'},
        preferredSettlement: pavlodar,
      );

      expect(filtered.map((job) => job.id).toList(), [
        'own-customer-role',
        'same-city',
      ]);
    },
  );

  test('jobMatchesSettlement matches by coordinates when available', () {
    final job = buildJob(
      id: 'same-coords',
      city: 'Павлодар',
      region: 'Павлодарская область',
      customerId: 'customer-1',
      lat: 52.29,
      lon: 76.96,
    );

    expect(jobMatchesSettlement(job, pavlodar), isTrue);
  });

  test(
    'filterAvailableExecutorJobs keeps non-own jobs when city is not set',
    () {
      final jobs = [
        buildJob(
          id: 'own',
          city: 'Алматы',
          region: 'Алматинская область',
          customerId: 'executor-1',
        ),
        buildJob(
          id: 'other',
          city: 'Астана',
          region: 'Акмолинская область',
          customerId: 'customer-1',
        ),
      ];

      final filtered = filterAvailableExecutorJobs(
        jobs,
        currentUserId: 'executor-1',
      );

      expect(filtered.map((job) => job.id).toList(), ['own', 'other']);
    },
  );

  test('filterAvailableExecutorJobs hides only executor-owned jobs', () {
    final jobs = [
      buildJob(
        id: 'executor-job',
        city: 'Павлодар',
        region: 'Павлодарская область',
        customerId: 'executor-2',
        ownerRole: 'executor',
      ),
      buildJob(
        id: 'customer-job',
        city: 'Павлодар',
        region: 'Павлодарская область',
        customerId: 'customer-1',
      ),
      buildJob(
        id: 'cancelled-customer-job',
        city: 'Павлодар',
        region: 'Павлодарская область',
        customerId: 'customer-2',
        status: 'cancelled',
      ),
    ];

    final filtered = filterAvailableExecutorJobs(
      jobs,
      currentUserId: 'executor-1',
      executorUserIds: {'executor-1', 'executor-2'},
      preferredSettlement: pavlodar,
    );

    expect(filtered.map((job) => job.id).toList(), ['customer-job']);
  });
}
