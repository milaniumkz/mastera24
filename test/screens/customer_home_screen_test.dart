import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/job.dart';
import 'package:mastera24/models/settlement_location.dart';
import 'package:mastera24/screens/customer/customer_home_screen.dart';

void main() {
  Job buildJob({
    required String id,
    required String category,
    required String city,
    String ownerRole = 'executor',
    String status = 'open',
    DateTime? scheduledAt,
  }) {
    return Job(
      id: id,
      title: category,
      description: 'Описание',
      category: category,
      city: city,
      cityRegion: '$city область',
      budget: 1000,
      bidFeeKzt: 0,
      customerId: 'executor-1',
      ownerRole: ownerRole,
      status: status,
      scheduledAt: scheduledAt ?? DateTime(2026, 8, 10),
      createdAt: DateTime(2026, 8, 1),
    );
  }

  const pavlodar = SettlementLocation(
    city: 'Павлодар',
    displayName: 'Павлодар',
    region: 'Павлодар область',
    latitude: 52.287,
    longitude: 76.967,
    type: 'city',
  );

  test('executorListingMatchesFilters uses job fields only', () {
    final matching = buildJob(
      id: 'listing-1',
      category: 'электрик',
      city: 'Павлодар',
      scheduledAt: DateTime(2026, 8, 10),
    );
    final wrongCategory = buildJob(
      id: 'listing-2',
      category: 'грузчики',
      city: 'Павлодар',
    );
    final customerJob = buildJob(
      id: 'customer-job',
      category: 'электрик',
      city: 'Павлодар',
      ownerRole: 'customer',
    );
    final otherCity = buildJob(
      id: 'listing-3',
      category: 'электрик',
      city: 'Алматы',
    );
    final cancelled = buildJob(
      id: 'listing-4',
      category: 'электрик',
      city: 'Павлодар',
      status: 'cancelled',
    );

    expect(
      executorListingMatchesFilters(
        matching,
        selectedCategory: 'электрик',
        selectedDate: DateTime(2026, 8, 10),
        preferredSettlement: pavlodar,
      ),
      isTrue,
    );
    expect(
      executorListingMatchesFilters(
        wrongCategory,
        selectedCategory: 'электрик',
        preferredSettlement: pavlodar,
      ),
      isFalse,
    );
    expect(
      executorListingMatchesFilters(
        customerJob,
        selectedCategory: 'электрик',
        preferredSettlement: pavlodar,
      ),
      isFalse,
    );
    expect(
      executorListingMatchesFilters(
        otherCity,
        selectedCategory: 'электрик',
        preferredSettlement: pavlodar,
      ),
      isFalse,
    );
    expect(
      executorListingMatchesFilters(
        cancelled,
        selectedCategory: 'электрик',
        preferredSettlement: pavlodar,
      ),
      isFalse,
    );
  });
}
