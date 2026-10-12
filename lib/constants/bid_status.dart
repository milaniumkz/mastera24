abstract final class BidStatus {
  static const String pendingPayment = 'pending_payment';
  static const String submitted = 'submitted';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
  static const String withdrawn = 'withdrawn';

  static const Set<String> active = {pendingPayment, submitted, accepted};
}
