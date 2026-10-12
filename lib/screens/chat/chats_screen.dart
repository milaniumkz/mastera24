import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/chat_thread.dart';
import '../../services/firestore_service.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/user_avatar.dart';
import 'chat_screen.dart';

List<ChatThread> sortChatsForDisplay(Iterable<ChatThread> chats) {
  final items = chats.toList();
  items.sort((left, right) {
    final leftDate = left.lastMessageAt ?? left.updatedAt;
    final rightDate = right.lastMessageAt ?? right.updatedAt;
    return rightDate.compareTo(leftDate);
  });
  return items;
}

class ChatsScreen extends StatelessWidget {
  final String currentUserId;
  final String title;

  const ChatsScreen({
    super.key,
    required this.currentUserId,
    this.title = 'Чаты',
  });

  String _formatTimestamp(DateTime? date) {
    if (date == null) {
      return '';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Не удалось загрузить чаты. Откройте раздел заново.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = sortChatsForDisplay(
            snapshot.data!.docs.map(ChatThread.fromDoc),
          );

          return PremiumPageBody(
            maxWidth: 1240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumHeroBanner(
                  eyebrow: '',
                  title: 'Чаты',
                  subtitle: '',
                  stats: [
                    PremiumStatChip(
                      label: 'Диалогов',
                      value: '${chats.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: chats.isEmpty
                      ? const PremiumEmptyState(
                          title: 'Пока нет активных диалогов',
                          subtitle:
                              'После принятия отклика или нового сообщения здесь появятся все рабочие переписки.',
                          icon: Icons.chat_bubble_outline,
                        )
                      : PremiumPanel(
                          child: ListView.separated(
                            itemCount: chats.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              return _ChatTile(
                                chat: chat,
                                currentUserId: currentUserId,
                                timestamp: _formatTimestamp(
                                  chat.lastMessageAt ?? chat.updatedAt,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatThread chat;
  final String currentUserId;
  final String timestamp;

  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.timestamp,
  });

  Future<Map<String, String>> _loadPreview() async {
    final service = FirestoreService();
    final otherUserId = chat.otherParticipantId(currentUserId);

    final userFuture = service.getUserProfile(otherUserId);
    final jobFuture = service.jobs.doc(chat.jobId).get();
    final userSnapshot = await userFuture;
    final jobSnapshot = await jobFuture;
    final userData = userSnapshot.data();
    final jobData = jobSnapshot.data();
    final otherName = userData?['name']?.toString();
    final otherRole = userData?['role']?.toString();
    final jobTitle = jobData?['title']?.toString();

    return {
      'title': otherName?.isNotEmpty == true
          ? otherName!
          : otherRole == 'executor'
          ? 'Исполнитель'
          : 'Заказчик',
      'subtitle': jobTitle?.isNotEmpty == true ? jobTitle! : 'Чат по заявке',
      'avatarUrl': userData?['avatarUrl']?.toString() ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _loadPreview(),
      builder: (context, snapshot) {
        final preview = snapshot.data;
        final title = preview?['title'] ?? 'Диалог';
        final subtitle = preview?['subtitle'] ?? 'Чат по заявке';
        final avatarUrl = preview?['avatarUrl'] ?? '';
        final lastMessage = chat.lastMessageText.trim().isEmpty
            ? 'Начните переписку'
            : chat.lastMessageText.trim();

        return InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(chatId: chat.id, title: subtitle),
              ),
            );
          },
          child: PremiumPanel(
            accented: true,
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  imageUrl: avatarUrl,
                  name: title,
                  radius: 24,
                  bordered: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (chat.hasUnreadMessages(currentUserId))
                        const Text(
                          'Новое сообщение',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 6),
                      Text(subtitle),
                      const SizedBox(height: 8),
                      Text(
                        lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                if (timestamp.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
