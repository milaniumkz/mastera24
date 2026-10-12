import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/constants/bid_status.dart';
import 'package:mastera24/models/bid.dart';
import 'package:mastera24/screens/customer/customer_job_detail_screen.dart';

void main() {
  test('hides pending payment bids from customer view', () {
    final bids = [
      Bid(
        id: '1',
        jobId: 'job',
        customerId: 'customer',
        executorId: 'executor-1',
        price: 1000,
        comment: 'pending',
        status: 'pending_payment',
        createdAt: DateTime(2025),
      ),
      Bid(
        id: '2',
        jobId: 'job',
        customerId: 'customer',
        executorId: 'executor-2',
        price: 2000,
        comment: 'submitted',
        status: 'submitted',
        createdAt: DateTime(2025),
      ),
    ];

    final visible = visibleBidsForCustomer(bids);

    expect(visible, hasLength(1));
    expect(visible.single.id, '2');
  });

  test('customer can review submitted and accepted bids', () {
    expect(canCustomerReviewBid(BidStatus.submitted), isTrue);
    expect(canCustomerReviewBid(BidStatus.accepted), isTrue);
    expect(canCustomerReviewBid(BidStatus.pendingPayment), isFalse);
    expect(canCustomerReviewBid(BidStatus.rejected), isFalse);
  });
}
