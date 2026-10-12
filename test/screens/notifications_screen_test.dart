import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/models/user_notification.dart';
import 'package:mastera24/screens/notifications/notifications_screen.dart';

void main() {
  test('sorts notifications by newest first', () {
    final older = UserNotification(
      id: 'older',
      recipientId: 'u1',
      type: 'chat_message',
      title: 'Older',
      body: 'Body',
      data: const {},
      createdAt: DateTime(2025, 1, 1),
      readAt: null,
    );
    final newer = UserNotification(
      id: 'newer',
      recipientId: 'u1',
      type: 'new_bid',
      title: 'Newer',
      body: 'Body',
      data: const {},
      createdAt: DateTime(2025, 1, 2),
      readAt: null,
    );

    final sorted = sortNotificationsByDate([older, newer]);

    expect(sorted.map((notification) => notification.id), ['newer', 'older']);
  });
}
