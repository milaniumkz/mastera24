import 'package:cloud_firestore/cloud_firestore.dart';

class ExecutorReview {
  final String id;
  final String bidId;
  final String jobId;
  final String customerId;
  final String customerName;
  final String customerAvatarUrl;
  final String executorId;
  final int rating;
  final String comment;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExecutorReview({
    required this.id,
    required this.bidId,
    required this.jobId,
    required this.customerId,
    required this.customerName,
    required this.customerAvatarUrl,
    required this.executorId,
    required this.rating,
    required this.comment,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExecutorReview.fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime? fallbackNow,
  }) {
    final now = fallbackNow ?? DateTime.now();
    return ExecutorReview(
      id: id,
      bidId: data['bidId']?.toString() ?? id,
      jobId: data['jobId']?.toString() ?? '',
      customerId: data['customerId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      customerAvatarUrl: data['customerAvatarUrl']?.toString() ?? '',
      executorId: data['executorId']?.toString() ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment']?.toString() ?? '',
      photoUrls: (data['photoUrls'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  factory ExecutorReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ExecutorReview.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'bidId': bidId,
      'jobId': jobId,
      'customerId': customerId,
      'customerName': customerName,
      'customerAvatarUrl': customerAvatarUrl,
      'executorId': executorId,
      'rating': rating,
      'comment': comment,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

List<ExecutorReview> sortExecutorReviews(Iterable<ExecutorReview> reviews) {
  final items = reviews.toList();
  items.sort((left, right) => right.createdAt.compareTo(left.createdAt));
  return items;
}

double averageExecutorRating(Iterable<ExecutorReview> reviews) {
  final items = reviews.toList();
  if (items.isEmpty) {
    return 0;
  }
  final total = items.fold<int>(0, (acc, review) => acc + review.rating);
  return total / items.length;
}
