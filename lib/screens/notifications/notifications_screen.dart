import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_catalogs.dart';
import '../../models/user_notification.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

List<UserNotification> sortNotificationsByDate(
  Iterable<UserNotification> notifications,
) {
  final items = notifications.toList()
    ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  return items;
}

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _markedNewJobsRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _markedNewJobsRead) return;
      _markedNewJobsRead = true;
      FirestoreService().markNotificationsReadByTypes(
        recipientId: widget.userId,
        types: const {'new_job'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.watchUserProfile(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!.data() ?? {};
          final role = profile['role']?.toString() == 'executor'
              ? 'executor'
              : 'customer';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.watchUserNotifications(widget.userId),
            builder: (context, notificationsSnapshot) {
              if (!notificationsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = sortNotificationsByDate(
                notificationsSnapshot.data!.docs.map(UserNotification.fromDoc),
              );

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length + 1,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _NotificationCategorySettings(
                      userId: widget.userId,
                      role: role,
                      profile: profile,
                    );
                  }

                  final notification = notifications[index - 1];
                  return Card(
                    color: notification.isRead
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.12),
                    child: ListTile(
                      title: Text(notification.title),
                      subtitle: Text(notification.body),
                      trailing: notification.isRead
                          ? null
                          : const Icon(Icons.circle, size: 10),
                      onTap: () async {
                        await NotificationService().handleNotificationPayload({
                          ...notification.data,
                          'type': notification.type,
                          'notificationId': notification.id,
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCategorySettings extends StatelessWidget {
  final String userId;
  final String role;
  final Map<String, dynamic> profile;

  const _NotificationCategorySettings({
    required this.userId,
    required this.role,
    required this.profile,
  });

  List<String> _selectedCategories() {
    final raw = profile['notificationCategoriesByRole'];
    final byRole = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    return (byRole[role] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .where((value) => value.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final selected = _selectedCategories().toSet();

    return FutureBuilder<AppCatalogs>(
      future: service.getAppCatalogs(),
      builder: (context, snapshot) {
        final categories =
            snapshot.data?.activeCategories
                .map((category) => category.name.trim())
                .where((name) => name.isNotEmpty)
                .toList() ??
            const <String>[];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Категории новых заказов',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  role == 'executor'
                      ? 'Выберите категории заказов заказчиков.'
                      : 'Выберите категории заявок исполнителей.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Все категории'),
                      selected: selected.isEmpty,
                      onSelected: (_) {
                        service.updateNotificationCategories(
                          uid: userId,
                          role: role,
                          categories: const [],
                        );
                      },
                    ),
                    ...categories.map(
                      (category) => FilterChip(
                        label: Text(category),
                        selected: selected.contains(category),
                        onSelected: (enabled) {
                          final next = selected.toSet();
                          if (enabled) {
                            next.add(category);
                          } else {
                            next.remove(category);
                          }
                          service.updateNotificationCategories(
                            uid: userId,
                            role: role,
                            categories: next.toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
