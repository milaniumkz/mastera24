import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotification {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  const UserNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    required this.readAt,
  });

  bool get isRead => readAt != null;

  factory UserNotification.fromMap(
    String id,
    Map<String, dynamic> map, {
    DateTime? fallbackNow,
  }) {
    return UserNotification(
      id: id,
      recipientId: map['recipientId']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? 'MASTERA 24',
      body: map['body']?.toString() ?? 'У вас новое уведомление.',
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          fallbackNow ??
          DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return UserNotification.fromMap(document.id, document.data() ?? {});
  }
}
