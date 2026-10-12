import 'package:cloud_functions/cloud_functions.dart';

import '../constants/payment_status.dart';

class PaymentService {
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Future<Map<String, dynamic>> createPaymentInvoice({
    required String bidId,
    required String jobId,
  }) async {
    final callable = _functions.httpsCallable('createPaymentInvoice');
    final result = await callable.call({'bidId': bidId, 'jobId': jobId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> registerClientResult({
    required String paymentId,
    required String status,
    Map<String, dynamic> payload = const {},
  }) async {
    final callable = _functions.httpsCallable('registerPaymentClientResult');
    await callable.call({
      'paymentId': paymentId,
      'status': status,
      'payload': payload,
    });
  }

  String mapSdkStatusToPaymentStatus(String sdkStatus) {
    switch (sdkStatus.toLowerCase()) {
      case 'success':
        return PaymentStatus.awaitingCallback;
      case 'failed':
      case 'error':
        return PaymentStatus.failed;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }
}
