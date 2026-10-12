import 'package:flutter/services.dart';

class EpaySdkResult {
  final String status;
  final Map<String, dynamic> payload;

  EpaySdkResult({required this.status, required this.payload});

  factory EpaySdkResult.fromMap(Map<String, dynamic> data) {
    return EpaySdkResult(
      status: data['status']?.toString() ?? 'unknown',
      payload: Map<String, dynamic>.from(data['payload'] as Map? ?? {}),
    );
  }
}

class EpaySdkService {
  static const MethodChannel _channel = MethodChannel('epay_sdk');

  Future<EpaySdkResult> pay({
    required String invoiceId,
    required int amount,
    required String accountId,
    required String description,
    required String postLink,
    required String failurePostLink,
    String? email,
    String? phone,
  }) async {
    final result = await _channel.invokeMethod<Map>(
      'pay',
      {
        'invoiceId': invoiceId,
        'amount': amount,
        'accountId': accountId,
        'description': description,
        'postLink': postLink,
        'failurePostLink': failurePostLink,
        'email': email,
        'phone': phone,
      },
    );

    if (result == null) {
      throw Exception('Платежный SDK не вернул ответ');
    }

    return EpaySdkResult.fromMap(Map<String, dynamic>.from(result));
  }
}
