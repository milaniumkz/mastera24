import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/constants/bid_status.dart';
import 'package:mastera24/screens/executor/executor_bid_detail_screen.dart';

void main() {
  test('canCallCustomer allows submitted and accepted bids', () {
    expect(canCallCustomer(BidStatus.submitted), isTrue);
    expect(canCallCustomer(BidStatus.accepted), isTrue);
    expect(canCallCustomer(BidStatus.pendingPayment), isFalse);
    expect(canCallCustomer(BidStatus.rejected), isFalse);
  });

  test('buildPhoneCallPath strips formatting and keeps plus prefix', () {
    expect(buildPhoneCallPath('+7 (705) 259-73-68'), '+77052597368');
    expect(buildPhoneCallPath('77052597368'), '+77052597368');
  });
}
