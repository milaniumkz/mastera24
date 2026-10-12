import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/app_catalogs.dart';
import 'package:mastera24/models/bid.dart';
import 'package:mastera24/models/executor_review.dart';
import 'package:mastera24/models/job.dart';
import 'package:mastera24/models/settlement_location.dart';
import 'package:mastera24/models/user_profile.dart';

void main() {
  group('Job', () {
    test('fromMap uses defaults and fallback time', () {
      final fallbackNow = DateTime(2025, 1, 2);
      final job = Job.fromMap('job-1', const {}, fallbackNow: fallbackNow);

      expect(job.id, 'job-1');
      expect(job.title, '');
      expect(job.status, 'open');
      expect(job.createdAt, fallbackNow);
    });

    test('toMap serializes date as Timestamp', () {
      final createdAt = DateTime(2025, 1, 2, 3, 4, 5);
      final scheduledAt = DateTime(2025, 1, 5);
      final job = Job(
        id: 'job-1',
        title: 'Fix sink',
        description: 'Kitchen sink repair',
        category: 'Ремонт',
        city: 'Алматы',
        cityRegion: 'Алматинская область',
        budget: 10000,
        bidFeeKzt: 300,
        customerId: 'customer-1',
        status: 'open',
        scheduledAt: scheduledAt,
        createdAt: createdAt,
      );

      final data = job.toMap();
      expect(data['title'], 'Fix sink');
      expect(data['city'], 'Алматы');
      expect(data['cityRegion'], 'Алматинская область');
      expect(data['bidFeeKzt'], 300);
      expect((data['scheduledAt'] as Timestamp).toDate(), scheduledAt);
      expect((data['createdAt'] as Timestamp).toDate(), createdAt);
    });
  });

  group('AppCatalogs', () {
    test('parses categories and cities from settings', () {
      final catalogs = AppCatalogs.fromSettings({
        'categories': [
          {
            'id': 'repair',
            'name': 'Ремонт',
            'bidFeeKzt': 450,
            'isActive': true,
          },
        ],
        'cities': ['Алматы', 'Астана'],
      });

      expect(catalogs.categories.single.name, 'Ремонт');
      expect(catalogs.categories.single.bidFeeKzt, 450);
      expect(catalogs.bidFeeForCategory('Ремонт'), 450);
      expect(catalogs.cities, ['Алматы', 'Астана']);
    });
  });

  group('Bid', () {
    test('fromMap uses defaults and fallback time', () {
      final fallbackNow = DateTime(2025, 2, 3);
      final bid = Bid.fromMap('bid-1', const {}, fallbackNow: fallbackNow);

      expect(bid.id, 'bid-1');
      expect(bid.status, 'pending_payment');
      expect(bid.createdAt, fallbackNow);
    });

    test('toMap serializes price and timestamp', () {
      final createdAt = DateTime(2025, 2, 3, 4, 5, 6);
      final bid = Bid(
        id: 'bid-1',
        jobId: 'job-1',
        customerId: 'customer-1',
        executorId: 'executor-1',
        price: 7000,
        comment: 'Ready to start',
        status: 'submitted',
        createdAt: createdAt,
      );

      final data = bid.toMap();
      expect(data['price'], 7000);
      expect((data['createdAt'] as Timestamp).toDate(), createdAt);
    });
  });

  group('ExecutorReview', () {
    test('fromMap reads rating and photo urls', () {
      final review = ExecutorReview.fromMap('bid-1', {
        'bidId': 'bid-1',
        'jobId': 'job-1',
        'customerId': 'customer-1',
        'customerName': 'Dana',
        'customerAvatarUrl': 'https://example.com/avatar.jpg',
        'executorId': 'executor-1',
        'rating': 5,
        'comment': 'Отличная работа',
        'photoUrls': ['https://example.com/1.jpg'],
      }, fallbackNow: DateTime(2025, 3, 4));

      expect(review.bidId, 'bid-1');
      expect(review.rating, 5);
      expect(review.photoUrls, ['https://example.com/1.jpg']);
    });

    test('averageExecutorRating and sortExecutorReviews work', () {
      final older = ExecutorReview(
        id: '1',
        bidId: '1',
        jobId: 'job',
        customerId: 'customer-1',
        customerName: 'A',
        customerAvatarUrl: '',
        executorId: 'executor',
        rating: 4,
        comment: '',
        photoUrls: const [],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final newer = ExecutorReview(
        id: '2',
        bidId: '2',
        jobId: 'job',
        customerId: 'customer-2',
        customerName: 'B',
        customerAvatarUrl: '',
        executorId: 'executor',
        rating: 5,
        comment: '',
        photoUrls: const [],
        createdAt: DateTime(2025, 1, 2),
        updatedAt: DateTime(2025, 1, 2),
      );

      expect(averageExecutorRating([older, newer]), 4.5);
      expect(sortExecutorReviews([older, newer]).first.id, '2');
    });
  });

  test('UserProfile.fromMap falls back to customer role', () {
    final profile = UserProfile.fromMap('user-1', const {
      'name': 'Dana',
      'avatarUrl': 'https://example.com/avatar.jpg',
    });

    expect(profile.uid, 'user-1');
    expect(profile.role, 'customer');
    expect(profile.name, 'Dana');
    expect(profile.phone, '');
    expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
    expect(profile.city, '');
    expect(profile.toMap(), {
      'role': 'customer',
      'name': 'Dana',
      'phone': '',
      'avatarUrl': 'https://example.com/avatar.jpg',
      'city': '',
      'cityRegion': '',
    });
  });

  test('SettlementLocation converts profile maps', () {
    final location = SettlementLocation.fromProfileMap({
      'city': 'Алматы',
      'cityRegion': 'Алматинская область',
      'cityLat': 43.238949,
      'cityLon': 76.889709,
    });

    expect(location.city, 'Алматы');
    expect(location.region, 'Алматинская область');
    expect(location.latitude, 43.238949);
  });
}
