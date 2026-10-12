import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/screens/executor/executor_job_detail_screen.dart';

void main() {
  test('bypasses bid payment on web', () {
    expect(shouldBypassBidPayment(isWeb: true, bidFeeKzt: 300), isTrue);
  });

  test('bypasses bid payment when fee is disabled', () {
    expect(shouldBypassBidPayment(isWeb: false, bidFeeKzt: 0), isTrue);
  });

  test('requires payment on mobile when fee is configured', () {
    expect(shouldBypassBidPayment(isWeb: false, bidFeeKzt: 300), isFalse);
  });

  test('executor tariff is active only before accessUntil', () {
    final now = DateTime(2026, 8, 20, 12);

    expect(
      hasActiveExecutorTariff(now.add(const Duration(hours: 1)), now),
      isTrue,
    );
    expect(
      hasActiveExecutorTariff(now.subtract(const Duration(minutes: 1)), now),
      isFalse,
    );
    expect(hasActiveExecutorTariff(null, now), isFalse);
  });
}
