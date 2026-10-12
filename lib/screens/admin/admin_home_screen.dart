import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_catalogs.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/premium_layout.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_panel_filters.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceMuted,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontSize: 22,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Админ-панель'),
          actions: [
            const NotificationBellButton(),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              icon: const Icon(Icons.person),
            ),
            IconButton(
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.accentSoft,
            indicatorColor: Colors.white,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Дашборд', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Пользователи', icon: Icon(Icons.people_outline)),
              Tab(text: 'Заявки', icon: Icon(Icons.assignment_outlined)),
              Tab(text: 'Отклики', icon: Icon(Icons.work_outline)),
              Tab(text: 'Чаты', icon: Icon(Icons.chat_bubble_outline)),
              Tab(text: 'Уведомления', icon: Icon(Icons.notifications_none)),
              Tab(text: 'Платежи', icon: Icon(Icons.payments_outlined)),
              Tab(text: 'Настройки', icon: Icon(Icons.tune)),
            ],
          ),
        ),
        body: Container(
          color: AppTheme.surfaceMuted,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeep,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2206132F),
                        blurRadius: 28,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: ColoredBox(
                      color: Colors.white,
                      child: TabBarView(
                        children: [
                          _DashboardTab(adminService: adminService),
                          _UsersTab(adminService: adminService),
                          _JobsTab(adminService: adminService),
                          _BidsTab(adminService: adminService),
                          _ChatsTab(adminService: adminService),
                          _NotificationsTab(adminService: adminService),
                          _PaymentsTab(adminService: adminService),
                          _SettingsTab(adminService: adminService),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final AdminService adminService;

  const _DashboardTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Управление платформой',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Здесь собраны ключевые сущности: пользователи, заказы, отклики, чаты, уведомления и платежи.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatsCard(
              title: 'Пользователи',
              icon: Icons.people_outline,
              stream: adminService.watchUsers(),
            ),
            _StatsCard(
              title: 'Заявки',
              icon: Icons.assignment_outlined,
              stream: adminService.watchJobs(),
            ),
            _StatsCard(
              title: 'Отклики',
              icon: Icons.work_outline,
              stream: adminService.watchBids(),
            ),
            _StatsCard(
              title: 'Чаты',
              icon: Icons.chat_bubble_outline,
              stream: adminService.watchChats(),
            ),
            _StatsCard(
              title: 'Уведомления',
              icon: Icons.notifications_none,
              stream: adminService.watchNotifications(),
            ),
            _StatsCard(
              title: 'Платежи',
              icon: Icons.payments_outlined,
              stream: adminService.watchPayments(),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _StatsCard({
    required this.title,
    required this.icon,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: PremiumPanel(
        accented: true,
        padding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  final AdminService adminService;

  const _UsersTab({required this.adminService});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _queryController = TextEditingController();
  String _query = '';
  String _role = 'all';
  String _status = 'all';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          queryController: _queryController,
          hintText: 'Поиск по имени, телефону, uid',
          onQueryChanged: (value) => setState(() => _query = value),
          filters: [
            _AdminDropdown(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все роли')),
                DropdownMenuItem(value: 'customer', child: Text('Заказчики')),
                DropdownMenuItem(value: 'executor', child: Text('Исполнители')),
                DropdownMenuItem(value: 'admin', child: Text('Админы')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'all'),
            ),
            _AdminDropdown(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все статусы')),
                DropdownMenuItem(value: 'active', child: Text('Активные')),
                DropdownMenuItem(
                  value: 'blocked',
                  child: Text('Заблокированные'),
                ),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'all'),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.adminService.watchUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final role = data['role']?.toString() ?? 'customer';
                final status = data['status']?.toString() ?? 'active';
                return adminMatchesQuery([
                      doc.id,
                      data['name']?.toString(),
                      data['phone']?.toString(),
                      role,
                      status,
                    ], _query) &&
                    adminMatchesFilter(role, _role) &&
                    adminMatchesFilter(status, _status);
              }).toList();

              if (users.isEmpty) {
                return const Center(child: Text('Пользователи не найдены.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data();
                  final role = data['role']?.toString() ?? 'customer';
                  final status = data['status']?.toString() ?? 'active';
                  final name = data['name']?.toString().trim();
                  final phone = data['phone']?.toString().trim();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name?.isNotEmpty == true ? name! : 'Без имени',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('UID: ${_shortId(doc.id)}')),
                              Chip(label: Text('Роль: $role')),
                              Chip(label: Text('Статус: $status')),
                              if (phone?.isNotEmpty == true)
                                Chip(label: Text(phone!)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () =>
                                    widget.adminService.setUserStatus(
                                      doc.id,
                                      status == 'blocked'
                                          ? 'active'
                                          : 'blocked',
                                    ),
                                child: Text(
                                  status == 'blocked'
                                      ? 'Разблокировать'
                                      : 'Заблокировать',
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) => widget.adminService
                                    .setUserRole(doc.id, value),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'customer',
                                    child: Text('Сделать заказчиком'),
                                  ),
                                  PopupMenuItem(
                                    value: 'executor',
                                    child: Text('Сделать исполнителем'),
                                  ),
                                  PopupMenuItem(
                                    value: 'admin',
                                    child: Text('Сделать админом'),
                                  ),
                                ],
                                child: const _ActionChipLabel(
                                  label: 'Изменить роль',
                                  icon: Icons.manage_accounts_outlined,
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
            },
          ),
        ),
      ],
    );
  }
}

class _JobsTab extends StatefulWidget {
  final AdminService adminService;

  const _JobsTab({required this.adminService});

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  final _queryController = TextEditingController();
  String _query = '';
  String _status = 'all';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          queryController: _queryController,
          hintText: 'Поиск по названию, описанию, заказчику',
          onQueryChanged: (value) => setState(() => _query = value),
          filters: [
            _AdminDropdown(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все статусы')),
                DropdownMenuItem(value: 'open', child: Text('Открытые')),
                DropdownMenuItem(value: 'blocked', child: Text('Скрытые')),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('Завершенные'),
                ),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'all'),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.adminService.watchJobs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final jobs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final status = data['status']?.toString() ?? 'open';
                return adminMatchesQuery([
                      doc.id,
                      data['title']?.toString(),
                      data['description']?.toString(),
                      data['customerId']?.toString(),
                      status,
                    ], _query) &&
                    adminMatchesFilter(status, _status);
              }).toList();

              if (jobs.isEmpty) {
                return const Center(child: Text('Заявки не найдены.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = jobs[index];
                  final data = doc.data();
                  final status = data['status']?.toString() ?? 'open';
                  final budget = (data['budget'] as num?)?.toInt() ?? 0;
                  final description = data['description']?.toString() ?? '';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title']?.toString() ?? 'Без названия',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('Бюджет: $budget KZT')),
                              Chip(label: Text('Статус: $status')),
                              Chip(
                                label: Text(
                                  'Заказчик: ${_shortId(data['customerId'])}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => widget.adminService
                                    .setJobStatus(doc.id, 'open'),
                                child: const Text('Открыть'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => widget.adminService
                                    .setJobStatus(doc.id, 'blocked'),
                                child: const Text('Скрыть'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => widget.adminService
                                    .setJobStatus(doc.id, 'completed'),
                                child: const Text('Завершить'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BidsTab extends StatefulWidget {
  final AdminService adminService;

  const _BidsTab({required this.adminService});

  @override
  State<_BidsTab> createState() => _BidsTabState();
}

class _BidsTabState extends State<_BidsTab> {
  final _queryController = TextEditingController();
  String _query = '';
  String _status = 'all';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          queryController: _queryController,
          hintText: 'Поиск по jobId, customerId, executorId, комментарию',
          onQueryChanged: (value) => setState(() => _query = value),
          filters: [
            _AdminDropdown(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все статусы')),
                DropdownMenuItem(
                  value: 'pending_payment',
                  child: Text('Ожидают оплату'),
                ),
                DropdownMenuItem(value: 'submitted', child: Text('Отправлены')),
                DropdownMenuItem(value: 'accepted', child: Text('Приняты')),
                DropdownMenuItem(value: 'rejected', child: Text('Отклонены')),
                DropdownMenuItem(value: 'cancelled', child: Text('Отменены')),
                DropdownMenuItem(value: 'withdrawn', child: Text('Отозваны')),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'all'),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.adminService.watchBids(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bids = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final status = data['status']?.toString() ?? '';
                return adminMatchesQuery([
                      doc.id,
                      data['jobId']?.toString(),
                      data['customerId']?.toString(),
                      data['executorId']?.toString(),
                      data['comment']?.toString(),
                      status,
                    ], _query) &&
                    adminMatchesFilter(status, _status);
              }).toList();

              if (bids.isEmpty) {
                return const Center(child: Text('Отклики не найдены.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bids.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = bids[index];
                  final data = doc.data();
                  final status = data['status']?.toString() ?? '';
                  final price = (data['price'] as num?)?.toInt() ?? 0;
                  final comment = data['comment']?.toString() ?? '';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Отклик ${_shortId(doc.id)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('Цена: $price KZT')),
                              Chip(label: Text('Статус: $status')),
                              Chip(
                                label: Text('Job: ${_shortId(data['jobId'])}'),
                              ),
                              Chip(
                                label: Text(
                                  'Исполнитель: ${_shortId(data['executorId'])}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(comment.isEmpty ? 'Без комментария' : comment),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => widget.adminService
                                    .setBidStatus(doc.id, 'submitted'),
                                child: const Text('Отправлен'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => widget.adminService
                                    .setBidStatus(doc.id, 'accepted'),
                                child: const Text('Принять'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => widget.adminService
                                    .setBidStatus(doc.id, 'rejected'),
                                child: const Text('Отклонить'),
                              ),
                              if (status == 'accepted')
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: doc.id,
                                          title: 'Чат по отклику',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Открыть чат'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatsTab extends StatefulWidget {
  final AdminService adminService;

  const _ChatsTab({required this.adminService});

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          queryController: _queryController,
          hintText: 'Поиск по chatId, jobId, участникам, сообщению',
          onQueryChanged: (value) => setState(() => _query = value),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.adminService.watchChats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final chats = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                return adminMatchesQuery([
                  doc.id,
                  data['jobId']?.toString(),
                  data['bidId']?.toString(),
                  data['customerId']?.toString(),
                  data['executorId']?.toString(),
                  data['lastMessageText']?.toString(),
                ], _query);
              }).toList();

              if (chats.isEmpty) {
                return const Center(child: Text('Чаты не найдены.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: chats.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = chats[index];
                  final data = doc.data();
                  final updatedAt = _formatDateTime(
                    _timestampToDate(data['updatedAt']),
                  );

                  return Card(
                    child: ListTile(
                      title: Text('Чат ${_shortId(doc.id)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Job: ${_shortId(data['jobId'])}'),
                          Text('Заказчик: ${_shortId(data['customerId'])}'),
                          Text('Исполнитель: ${_shortId(data['executorId'])}'),
                          const SizedBox(height: 4),
                          Text(
                            data['lastMessageText']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true
                                ? data['lastMessageText'].toString()
                                : 'Сообщений пока нет',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Text(updatedAt),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: doc.id,
                              title: 'Чат ${_shortId(doc.id)}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationsTab extends StatefulWidget {
  final AdminService adminService;

  const _NotificationsTab({required this.adminService});

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          queryController: _queryController,
          hintText: 'Поиск по типу, заголовку, тексту, получателю',
          onQueryChanged: (value) => setState(() => _query = value),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.adminService.watchNotifications(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                return adminMatchesQuery([
                  doc.id,
                  data['recipientId']?.toString(),
                  data['type']?.toString(),
                  data['title']?.toString(),
                  data['body']?.toString(),
                ], _query);
              }).toList();

              if (notifications.isEmpty) {
                return const Center(child: Text('Уведомления не найдены.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = notifications[index];
                  final data = doc.data();
                  final readAt = _timestampToDate(data['readAt']);

                  return Card(
                    child: ListTile(
                      title: Text(data['title']?.toString() ?? 'Без заголовка'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['body']?.toString() ?? ''),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  'Тип: ${data['type']?.toString() ?? 'system'}',
                                ),
                              ),
                              Chip(
                                label: Text(
                                  'Получатель: ${_shortId(data['recipientId'])}',
                                ),
                              ),
                              Chip(
                                label: Text(
                                  readAt == null ? 'Не прочитано' : 'Прочитано',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Text(
                        _formatDateTime(_timestampToDate(data['createdAt'])),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatefulWidget {
  final AdminService adminService;

  const _PaymentsTab({required this.adminService});

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          queryController: _queryController,
          hintText: 'Поиск по paymentId, bidId, executorId, статусу',
          onQueryChanged: (value) => setState(() => _query = value),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.adminService.watchPayments(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final payments = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                return adminMatchesQuery([
                  doc.id,
                  data['bidId']?.toString(),
                  data['executorId']?.toString(),
                  data['status']?.toString(),
                ], _query);
              }).toList();

              if (payments.isEmpty) {
                return const Center(child: Text('Платежи не найдены.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = payments[index];
                  final data = doc.data();
                  final status = data['status']?.toString() ?? 'created';
                  final amount = (data['amount'] as num?)?.toInt() ?? 0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Платеж ${_shortId(doc.id)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('Сумма: $amount KZT')),
                              Chip(label: Text('Статус: $status')),
                              Chip(
                                label: Text(
                                  'Исполнитель: ${_shortId(data['executorId'])}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () async {
                              final controller = TextEditingController();
                              final amount = await showDialog<int?>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Возврат'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Сумма (пусто = полный)',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(
                                          int.tryParse(controller.text.trim()),
                                        );
                                      },
                                      child: const Text('Вернуть'),
                                    ),
                                  ],
                                ),
                              );

                              await widget.adminService.refundPayment(
                                paymentId: doc.id,
                                amount: amount,
                              );
                            },
                            child: const Text('Сделать возврат'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatefulWidget {
  final AdminService adminService;

  const _SettingsTab({required this.adminService});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _controller = TextEditingController();
  final _homeTitleController = TextEditingController();
  final _homeDescriptionController = TextEditingController();
  final _homeButtonController = TextEditingController();
  bool _saving = false;
  bool _savingContent = false;
  bool _initialized = false;
  bool _contentInitialized = false;

  @override
  void dispose() {
    _controller.dispose();
    _homeTitleController.dispose();
    _homeDescriptionController.dispose();
    _homeButtonController.dispose();
    super.dispose();
  }

  Future<void> _saveCatalogs({
    required List<ServiceCategory> categories,
    required List<String> cities,
  }) {
    return widget.adminService.updateCatalogs(
      categories: categories,
      cities: cities,
    );
  }

  Future<ServiceCategory?> _showCategoryDialog({
    ServiceCategory? initial,
  }) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    var isActive = initial?.isActive ?? true;

    return showDialog<ServiceCategory>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                initial == null ? 'Новая категория' : 'Редактировать категорию',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    title: const Text('Категория активна'),
                    onChanged: (value) =>
                        setStateDialog(() => isActive = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      ServiceCategory(
                        id: initial?.id ?? _buildCategoryId(name),
                        name: name,
                        bidFeeKzt: initial?.bidFeeKzt ?? 0,
                        isActive: isActive,
                      ),
                    );
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showCityDialog({String? initial}) {
    final controller = TextEditingController(text: initial ?? '');

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? 'Новый город' : 'Редактировать город'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Город'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final city = controller.text.trim();
              if (city.isEmpty) {
                return;
              }
              Navigator.of(context).pop(city);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  String _buildCategoryId(String name) {
    final sanitized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9а-яё]+', caseSensitive: false), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return sanitized.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : sanitized;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('billing')
          .snapshots(),
      builder: (context, snapshot) {
        final fee = (snapshot.data?.data()?['bidFeeKzt'] as num?)?.toInt() ?? 0;
        if (!_initialized) {
          _controller.text = fee.toString();
          _initialized = true;
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: widget.adminService.watchCatalogSettings(),
          builder: (context, catalogSnapshot) {
            final catalogs = AppCatalogs.fromSettings(
              catalogSnapshot.data?.data(),
            );
            final categories = List<ServiceCategory>.from(catalogs.categories);
            final cities = List<String>.from(catalogs.cities);

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: widget.adminService.watchContentSettings(),
              builder: (context, contentSnapshot) {
                final content = contentSnapshot.data?.data() ?? {};
                if (!_contentInitialized) {
                  _homeTitleController.text =
                      content['homeTitle']?.toString() ?? '';
                  _homeDescriptionController.text =
                      content['homeDescription']?.toString() ?? '';
                  _homeButtonController.text =
                      content['homeButtonText']?.toString() ?? '';
                  _contentInitialized = true;
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Тарифы и системные настройки',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    PremiumPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Текст на главной',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Этот блок показывается заказчику над поиском исполнителей.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _homeTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Заголовок',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _homeDescriptionController,
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Описание / инструкция',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _homeButtonController,
                            decoration: const InputDecoration(
                              labelText: 'Текст кнопки',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _savingContent
                                ? null
                                : () async {
                                    setState(() => _savingContent = true);
                                    await widget.adminService.updateHomeContent(
                                      title: _homeTitleController.text.trim(),
                                      description: _homeDescriptionController
                                          .text
                                          .trim(),
                                      buttonText: _homeButtonController.text
                                          .trim(),
                                    );
                                    if (mounted) {
                                      setState(() => _savingContent = false);
                                    }
                                  },
                            child: Text(
                              _savingContent ? 'Сохраняем...' : 'Сохранить',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Резервная комиссия',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Используется только для старых заявок, где цена категории еще не сохранена.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Комиссия по умолчанию (KZT)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    final value = int.tryParse(
                                      _controller.text.trim(),
                                    );
                                    if (value == null || value < 0) return;

                                    setState(() => _saving = true);
                                    await widget.adminService.updateBidFee(
                                      value,
                                    );
                                    if (mounted) {
                                      setState(() => _saving = false);
                                    }
                                  },
                            child: Text(_saving ? 'Сохраняем...' : 'Сохранить'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Категории',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final created = await _showCategoryDialog();
                                  if (created == null) return;
                                  final next = [...categories, created];
                                  await _saveCatalogs(
                                    categories: next,
                                    cities: cities,
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...categories.map(
                            (category) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(category.name),
                                subtitle: Text(
                                  category.isActive ? 'Активна' : 'Скрыта',
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: category.isActive
                                          ? 'Скрыть'
                                          : 'Активировать',
                                      onPressed: () async {
                                        final next = categories
                                            .map(
                                              (item) => item.id == category.id
                                                  ? item.copyWith(
                                                      isActive: !item.isActive,
                                                    )
                                                  : item,
                                            )
                                            .toList();
                                        await _saveCatalogs(
                                          categories: next,
                                          cities: cities,
                                        );
                                      },
                                      icon: Icon(
                                        category.isActive
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Редактировать',
                                      onPressed: () async {
                                        final edited =
                                            await _showCategoryDialog(
                                              initial: category,
                                            );
                                        if (edited == null) return;
                                        final next = categories
                                            .map(
                                              (item) => item.id == category.id
                                                  ? edited
                                                  : item,
                                            )
                                            .toList();
                                        await _saveCatalogs(
                                          categories: next,
                                          cities: cities,
                                        );
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Удалить',
                                      onPressed: categories.length <= 1
                                          ? null
                                          : () async {
                                              final next = categories
                                                  .where(
                                                    (item) =>
                                                        item.id != category.id,
                                                  )
                                                  .toList();
                                              await _saveCatalogs(
                                                categories: next,
                                                cities: cities,
                                              );
                                            },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Города',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final city = await _showCityDialog();
                                  if (city == null) return;
                                  if (cities.contains(city)) return;
                                  await _saveCatalogs(
                                    categories: categories,
                                    cities: [...cities, city],
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_location_alt_outlined,
                                ),
                                label: const Text('Добавить'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: cities
                                .map(
                                  (city) => InputChip(
                                    label: Text(city),
                                    onPressed: () async {
                                      final edited = await _showCityDialog(
                                        initial: city,
                                      );
                                      if (edited == null) return;
                                      final next = cities
                                          .map(
                                            (item) =>
                                                item == city ? edited : item,
                                          )
                                          .toSet()
                                          .toList();
                                      await _saveCatalogs(
                                        categories: categories,
                                        cities: next,
                                      );
                                    },
                                    onDeleted: cities.length <= 1
                                        ? null
                                        : () async {
                                            final next = cities
                                                .where((item) => item != city)
                                                .toList();
                                            await _saveCatalogs(
                                              categories: categories,
                                              cities: next,
                                            );
                                          },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminToolbar extends StatelessWidget {
  final TextEditingController queryController;
  final String hintText;
  final ValueChanged<String> onQueryChanged;
  final List<Widget> filters;

  const _AdminToolbar({
    required this.queryController,
    required this.hintText,
    required this.onQueryChanged,
    this.filters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: queryController,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: hintText,
            ),
          ),
          if (filters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: filters),
          ],
        ],
      ),
    );
  }
}

class _AdminDropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _AdminDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
    );
  }
}

class _ActionChipLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActionChipLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

String _shortId(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.length <= 10) {
    return text;
  }
  return '${text.substring(0, 6)}...${text.substring(text.length - 4)}';
}

DateTime? _timestampToDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month $hour:$minute';
}
