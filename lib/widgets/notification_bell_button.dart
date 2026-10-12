import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_notification.dart';
import '../models/chat_thread.dart';
import '../screens/chat/chats_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../services/firestore_service.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: FirestoreService().watchUserNotifications(user.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData
            ? snapshot.data!.docs
                  .map(UserNotification.fromDoc)
                  .where(
                    (notification) =>
                        !notification.isRead && notification.type == 'new_job',
                  )
                  .length
            : 0;

        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              onPressed: () {
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(userId: user.uid),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ChatBadgeButton extends StatelessWidget {
  const ChatBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: FirestoreService().watchUserChats(user.uid),
      builder: (context, snapshot) {
        final hasUnreadChat = snapshot.hasData
            ? snapshot.data!.docs
                  .map(ChatThread.fromDoc)
                  .any((chat) => chat.hasUnreadMessages(user.uid))
            : false;

        return StreamBuilder(
          stream: FirestoreService().watchUserNotifications(user.uid),
          builder: (context, notificationsSnapshot) {
            final hasUnreadBid =
                notificationsSnapshot.hasData &&
                notificationsSnapshot.data!.docs
                    .map(UserNotification.fromDoc)
                    .any(
                      (notification) =>
                          !notification.isRead &&
                          {'new_bid', 'bid_status'}.contains(notification.type),
                    );
            return _buildButton(
              context,
              user.uid,
              hasUnreadChat || hasUnreadBid,
            );
          },
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, String uid, bool hasUnreadChat) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatsScreen(currentUserId: uid),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: hasUnreadChat ? 'Чаты: есть новые сообщения' : 'Чаты',
        ),
        if (hasUnreadChat)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
