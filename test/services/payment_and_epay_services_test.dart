import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/constants/payment_status.dart';
import 'package:mastera24/services/epay_sdk_service.dart';
import 'package:mastera24/services/payment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('epay_sdk');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PaymentService.mapSdkStatusToPaymentStatus', () {
    final service = PaymentService();

    test('maps success to awaiting callback', () {
      expect(
        service.mapSdkStatusToPaymentStatus('success'),
        PaymentStatus.awaitingCallback,
      );
    });

    test('maps errors to failed', () {
      expect(
        service.mapSdkStatusToPaymentStatus('error'),
        PaymentStatus.failed,
      );
      expect(
        service.mapSdkStatusToPaymentStatus('unknown'),
        PaymentStatus.failed,
      );
    });

    test('maps cancel aliases to cancelled', () {
      expect(
        service.mapSdkStatusToPaymentStatus('cancelled'),
        PaymentStatus.cancelled,
      );
      expect(
        service.mapSdkStatusToPaymentStatus('canceled'),
        PaymentStatus.cancelled,
      );
    });
  });

  test('EpaySdkResult.fromMap keeps unknown default and payload map', () {
    final result = EpaySdkResult.fromMap(const {
      'payload': {'ok': true},
    });

    expect(result.status, 'unknown');
    expect(result.payload, {'ok': true});
  });

  test('EpaySdkService.pay returns parsed SDK response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'pay');
          expect(call.arguments['invoiceId'], 'inv-1');
          return {
            'status': 'success',
            'payload': {'operationId': 'op-1'},
          };
        });

    final result = await EpaySdkService().pay(
      invoiceId: 'inv-1',
      amount: 9000,
      accountId: 'user-1',
      description: 'Оплата',
      postLink: 'https://ok',
      failurePostLink: 'https://fail',
    );

    expect(result.status, 'success');
    expect(result.payload['operationId'], 'op-1');
  });

  test('EpaySdkService.pay throws when SDK returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    await expectLater(
      () => EpaySdkService().pay(
        invoiceId: 'inv-1',
        amount: 9000,
        accountId: 'user-1',
        description: 'Оплата',
        postLink: 'https://ok',
        failurePostLink: 'https://fail',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
