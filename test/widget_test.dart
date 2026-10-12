import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/config/app_config.dart';

void main() {
  test('app config defaults stay stable', () {
    expect(AppConfig.flavor, 'prod');
    expect(AppConfig.bidFeeKzt, 0);
    expect(AppConfig.currency, 'KZT');
    expect(
      AppConfig.paymentSuccessUrl,
      'https://mastera24.app/payment/success',
    );
    expect(
      AppConfig.paymentFailureUrl,
      'https://mastera24.app/payment/failure',
    );
  });
}
