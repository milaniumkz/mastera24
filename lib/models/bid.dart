import 'package:cloud_firestore/cloud_firestore.dart';

class Bid {
  final String id;
  final String jobId;
  final String customerId;
  final String executorId;
  final int price;
  final String comment;
  final String status;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.jobId,
    required this.customerId,
    required this.executorId,
    required this.price,
    required this.comment,
    required this.status,
    required this.createdAt,
  });

  factory Bid.fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime? fallbackNow,
  }) {
    return Bid(
      id: id,
      jobId: data['jobId'] ?? '',
      customerId: data['customerId'] ?? '',
      executorId: data['executorId'] ?? '',
      price: (data['price'] ?? 0) as int,
      comment: data['comment'] ?? '',
      status: data['status'] ?? 'pending_payment',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          fallbackNow ??
          DateTime.now(),
    );
  }

  factory Bid.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Bid.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'customerId': customerId,
      'executorId': executorId,
      'price': price,
      'comment': comment,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
