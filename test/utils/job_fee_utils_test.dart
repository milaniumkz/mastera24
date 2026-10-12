import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/app_catalogs.dart';
import 'package:mastera24/models/job.dart';
import 'package:mastera24/utils/job_fee_utils.dart';

void main() {
  test('prefers fee stored in job', () {
    final job = Job(
      id: 'job-1',
      title: 'Test',
      description: 'Desc',
      category: 'Ремонт',
      city: 'Алматы',
      cityRegion: 'Алматинская область',
      budget: 1000,
      bidFeeKzt: 700,
      customerId: 'customer-1',
      status: 'open',
      scheduledAt: DateTime(2025, 1, 5),
      createdAt: DateTime(2025, 1, 1),
    );

    final fee = resolveJobBidFeeKzt(
      job: job,
      catalogs: AppCatalogs.defaults(),
      legacyBidFeeKzt: 100,
    );

    expect(fee, 700);
  });

  test('falls back to category fee and then legacy fee', () {
    final jobWithoutFee = Job(
      id: 'job-1',
      title: 'Test',
      description: 'Desc',
      category: 'Ремонт',
      city: 'Алматы',
      cityRegion: 'Алматинская область',
      budget: 1000,
      bidFeeKzt: 0,
      customerId: 'customer-1',
      status: 'open',
      scheduledAt: DateTime(2025, 1, 5),
      createdAt: DateTime(2025, 1, 1),
    );

    expect(
      resolveJobBidFeeKzt(
        job: jobWithoutFee,
        catalogs: AppCatalogs.defaults(),
        legacyBidFeeKzt: 100,
      ),
      300,
    );

    final unknownCategoryJob = Job(
      id: 'job-2',
      title: 'Test',
      description: 'Desc',
      category: 'Другое',
      city: 'Алматы',
      cityRegion: 'Алматинская область',
      budget: 1000,
      bidFeeKzt: 0,
      customerId: 'customer-1',
      status: 'open',
      scheduledAt: DateTime(2025, 1, 5),
      createdAt: DateTime(2025, 1, 1),
    );

    expect(
      resolveJobBidFeeKzt(
        job: unknownCategoryJob,
        catalogs: AppCatalogs.defaults(),
        legacyBidFeeKzt: 100,
      ),
      100,
    );
  });
}
