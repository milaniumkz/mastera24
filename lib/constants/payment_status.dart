abstract final class PaymentStatus {
  static const String created = 'created';
  static const String sdkStarted = 'sdk_started';
  static const String awaitingCallback = 'awaiting_callback';
  static const String paid = 'paid';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
  static const String refundRequested = 'refund_requested';
  static const String refunded = 'refunded';

  static const Set<String> active = {created, sdkStarted, awaitingCallback};
}
