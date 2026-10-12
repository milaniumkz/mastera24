import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/job.dart';
import 'package:mastera24/screens/customer/my_orders_screen.dart';

void main() {
  Job buildJob({
    required String id,
    required String ownerRole,
    required String status,
  }) {
    return Job(
      id: id,
      title: 'Заявка',
      description: 'Описание',
      category: 'Ремонт',
      city: 'Павлодар',
      cityRegion: 'Павлодарская область',
      budget: 1000,
      bidFeeKzt: 0,
      customerId: 'user-1',
      ownerRole: ownerRole,
      status: status,
      scheduledAt: DateTime(2026, 9, 3),
      createdAt: DateTime(2026, 9, 1),
    );
  }

  test('activeJobsForOwnerRole hides cancelled jobs by role', () {
    final jobs = [
      buildJob(id: 'customer-open', ownerRole: 'customer', status: 'open'),
      buildJob(
        id: 'customer-cancelled',
        ownerRole: 'customer',
        status: 'cancelled',
      ),
      buildJob(id: 'executor-open', ownerRole: 'executor', status: 'open'),
      buildJob(
        id: 'executor-cancelled',
        ownerRole: 'executor',
        status: 'cancelled',
      ),
    ];

    expect(activeJobsForOwnerRole(jobs, 'customer').map((job) => job.id), [
      'customer-open',
    ]);
    expect(activeJobsForOwnerRole(jobs, 'executor').map((job) => job.id), [
      'executor-open',
    ]);
  });
}
