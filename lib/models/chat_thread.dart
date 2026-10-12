import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final String jobId;
  final String bidId;
  final String customerId;
  final String executorId;
  final List<String> participantIds;
  final String lastMessageText;
  final String lastSenderId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> incomingAt;
  final Map<String, dynamic> readAt;

  const ChatThread({
    required this.id,
    required this.jobId,
    required this.bidId,
    required this.customerId,
    required this.executorId,
    required this.participantIds,
    required this.lastMessageText,
    required this.lastSenderId,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.incomingAt = const {},
    this.readAt = const {},
  });

  Timestamp? unreadIncomingAt(String uid) {
    final incoming =
        incomingAt[uid] ??
        (lastSenderId.isNotEmpty && lastSenderId != uid && lastMessageAt != null
            ? Timestamp.fromDate(lastMessageAt!)
            : null);
    final read = readAt[uid];
    if (incoming is! Timestamp) return null;
    return read is! Timestamp || incoming.compareTo(read) > 0 ? incoming : null;
  }

  bool hasUnreadMessages(String uid) => unreadIncomingAt(uid) != null;

  String otherParticipantId(String currentUserId) {
    if (currentUserId == customerId) {
      return executorId;
    }
    return customerId;
  }

  factory ChatThread.fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime? fallbackNow,
  }) {
    final now = fallbackNow ?? DateTime.now();
    return ChatThread(
      id: id,
      jobId: data['jobId']?.toString() ?? '',
      bidId: data['bidId']?.toString() ?? id,
      customerId: data['customerId']?.toString() ?? '',
      executorId: data['executorId']?.toString() ?? '',
      participantIds: (data['participantIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      lastMessageText: data['lastMessageText']?.toString() ?? '',
      lastSenderId: data['lastSenderId']?.toString() ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
      incomingAt: Map<String, dynamic>.from(data['incomingAt'] as Map? ?? {}),
      readAt: Map<String, dynamic>.from(data['readAt'] as Map? ?? {}),
    );
  }

  factory ChatThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ChatThread.fromMap(doc.id, doc.data() ?? {});
  }
}
