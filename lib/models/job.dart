import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/job_status.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String category;
  final String city;
  final String cityDisplayName;
  final String cityRegion;
  final double cityLat;
  final double cityLon;
  final String cityType;
  final int budget;
  final int bidFeeKzt;
  final String customerId;
  final String ownerRole;
  final String status;
  final DateTime? scheduledAt;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    this.cityDisplayName = '',
    required this.cityRegion,
    this.cityLat = 0,
    this.cityLon = 0,
    this.cityType = '',
    required this.budget,
    required this.bidFeeKzt,
    required this.customerId,
    this.ownerRole = 'customer',
    required this.status,
    this.scheduledAt,
    required this.createdAt,
  });

  factory Job.fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime? fallbackNow,
  }) {
    return Job(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      city: data['city'] ?? '',
      cityDisplayName: data['cityDisplayName']?.toString() ?? '',
      cityRegion: data['cityRegion'] ?? '',
      cityLat: (data['cityLat'] as num?)?.toDouble() ?? 0,
      cityLon: (data['cityLon'] as num?)?.toDouble() ?? 0,
      cityType: data['cityType']?.toString() ?? '',
      budget: (data['budget'] ?? 0) as int,
      bidFeeKzt: (data['bidFeeKzt'] as num?)?.toInt() ?? 0,
      customerId: data['customerId'] ?? '',
      ownerRole: data['ownerRole']?.toString() ?? 'customer',
      status: data['status'] ?? 'open',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          fallbackNow ??
          DateTime.now(),
    );
  }

  factory Job.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Job.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'city': city,
      'cityDisplayName': cityDisplayName,
      'cityRegion': cityRegion,
      'cityLat': cityLat,
      'cityLon': cityLon,
      'cityType': cityType,
      'budget': budget,
      'bidFeeKzt': bidFeeKzt,
      'customerId': customerId,
      'ownerRole': ownerRole,
      'status': status,
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isOpen => JobStatus.isOpen(status);
  bool get isCustomerJob => ownerRole == 'customer';
  bool get isExecutorJob => ownerRole == 'executor';
}
