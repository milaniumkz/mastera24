import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/chat_thread.dart';
import 'package:mastera24/screens/chat/chats_screen.dart';

void main() {
  test('incoming messages stay unread when the user sends a reply', () {
    final incoming = Timestamp.fromDate(DateTime(2026, 9, 30, 12));
    final chat = ChatThread.fromMap('chat', {
      'lastSenderId': 'executor',
      'incomingAt': {'executor': incoming},
    });
    expect(chat.hasUnreadMessages('executor'), isTrue);
    expect(chat.hasUnreadMessages('customer'), isFalse);
    final readChat = ChatThread.fromMap('chat', {
      'incomingAt': {'executor': incoming},
      'readAt': {'executor': incoming},
    });
    expect(readChat.hasUnreadMessages('executor'), isFalse);
  });

  test('a new reply after reading lights the badge again', () {
    final chat = ChatThread.fromMap('chat', {
      'incomingAt': {'executor': Timestamp(200, 0)},
      'readAt': {'executor': Timestamp(100, 0)},
    });
    expect(chat.hasUnreadMessages('executor'), isTrue);
  });

  test('legacy chats use the last incoming message until read', () {
    final messageAt = Timestamp(100, 0);
    final data = {'lastSenderId': 'customer', 'lastMessageAt': messageAt};
    expect(
      ChatThread.fromMap('chat', data).hasUnreadMessages('executor'),
      isTrue,
    );
    expect(
      ChatThread.fromMap('chat', data).hasUnreadMessages('customer'),
      isFalse,
    );
    expect(
      ChatThread.fromMap('chat', {
        ...data,
        'readAt': {'executor': messageAt},
      }).hasUnreadMessages('executor'),
      isFalse,
    );
  });
  test('creates chat thread from firestore map', () {
    final chat = ChatThread.fromMap('chat-1', {
      'jobId': 'job-1',
      'bidId': 'bid-1',
      'customerId': 'customer-1',
      'executorId': 'executor-1',
      'participantIds': ['customer-1', 'executor-1'],
      'lastMessageText': 'Привет',
      'lastSenderId': 'executor-1',
      'lastMessageAt': Timestamp.fromDate(DateTime(2025, 1, 2, 14, 30)),
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
      'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 2, 14, 31)),
    });

    expect(chat.jobId, 'job-1');
    expect(chat.bidId, 'bid-1');
    expect(chat.lastMessageText, 'Привет');
    expect(chat.otherParticipantId('customer-1'), 'executor-1');
  });

  test('sorts chats by latest activity first', () {
    final older = ChatThread.fromMap('older', {
      'customerId': 'c1',
      'executorId': 'e1',
      'participantIds': ['c1', 'e1'],
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
      'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 1, 12, 0)),
    });
    final newer = ChatThread.fromMap('newer', {
      'customerId': 'c1',
      'executorId': 'e2',
      'participantIds': ['c1', 'e2'],
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 2, 12, 0)),
      'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 2, 12, 0)),
      'lastMessageAt': Timestamp.fromDate(DateTime(2025, 1, 3, 10, 0)),
    });

    final sorted = sortChatsForDisplay([older, newer]);

    expect(sorted.map((chat) => chat.id), ['newer', 'older']);
  });
}
