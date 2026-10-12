import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_catalogs.dart';
import '../../models/job.dart';
import '../../models/settlement_location.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/user_avatar.dart';
import '../customer/create_job_screen.dart';
import '../executor/executor_profile_view_screen.dart';
import '../profile/profile_screen.dart';

List<String> customerFilterCategories(AppCatalogs catalogs) {
  final categories =
      catalogs.activeCategories
          .map((category) => category.name.trim())
          .where((value) => value.isNotEmpty)
          .toList()
        ..sort();
  return categories;
}

bool executorListingMatchesFilters(
  Job job, {
  String selectedCategory = 'all',
  DateTime? selectedDate,
  SettlementLocation? preferredSettlement,
}) {
  if (!job.isOpen || !job.isExecutorJob) return false;
  if (selectedCategory != 'all' && job.category != selectedCategory) {
    return false;
  }
  if (selectedDate != null &&
      (job.scheduledAt == null ||
          !DateUtils.isSameDay(job.scheduledAt, selectedDate))) {
    return false;
  }
  return executorListingMatchesSettlement(job, preferredSettlement);
}

bool executorListingMatchesSettlement(
  Job job,
  SettlementLocation? preferredSettlement,
) {
  if (preferredSettlement == null || preferredSettlement.isEmpty) return true;

  final hasCoordinates =
      preferredSettlement.latitude != 0 &&
      preferredSettlement.longitude != 0 &&
      job.cityLat != 0 &&
      job.cityLon != 0;
  if (hasCoordinates) {
    final latDiff = (preferredSettlement.latitude - job.cityLat).abs();
    final lonDiff = (preferredSettlement.longitude - job.cityLon).abs();
    if (latDiff <= 0.05 && lonDiff <= 0.05) return true;
  }

  final cityMatches =
      job.city.trim().toLowerCase() ==
      preferredSettlement.city.trim().toLowerCase();
  if (!cityMatches) return false;

  final jobRegion = job.cityRegion.trim().toLowerCase();
  final preferredRegion = preferredSettlement.region.trim().toLowerCase();
  return jobRegion.isEmpty ||
      preferredRegion.isEmpty ||
      jobRegion == preferredRegion;
}

class CustomerHomeScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> profile;

  const CustomerHomeScreen({
    super.key,
    required this.userId,
    required this.profile,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late final Future<AppCatalogs> _catalogsFuture;
  String _selectedCategory = 'all';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _catalogsFuture = FirestoreService().getAppCatalogs();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'all' || _selectedDate != null;

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'all';
      _selectedDate = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      locale: const Locale('ru'),
    );
    if (selected == null) return;
    setState(() => _selectedDate = DateUtils.dateOnly(selected));
  }

  Future<void> _pickCategory(List<String> categories) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Найти исполнителей'),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.apps_outlined),
                  title: const Text('Все категории'),
                  trailing: _selectedCategory == 'all'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop('all'),
                ),
                ...categories.map(
                  (category) => ListTile(
                    leading: const Icon(Icons.layers_outlined),
                    title: Text(category),
                    trailing: _selectedCategory == category
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(category),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
    if (selected == null) return;
    setState(() => _selectedCategory = selected);
  }

  Widget _buildCategoryButton({
    required bool isWide,
    required List<String> categories,
  }) {
    return SizedBox(
      width: isWide ? 300 : double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _pickCategory(categories),
        icon: const Icon(Icons.layers_outlined),
        label: Row(
          children: [
            Expanded(
              child: Text(
                _selectedCategory == 'all'
                    ? 'Все категории'
                    : _selectedCategory,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }

  void _openExecutorListing(String executorId, Job listingJob) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExecutorProfileViewScreen(
          executorId: executorId,
          listingJob: listingJob,
        ),
      ),
    );
  }

  void _openCreateJob(SettlementLocation settlement) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateJobScreen(
          initialSettlement: settlement.isEmpty ? null : settlement,
        ),
      ),
    );
  }

  String _homeDescription(Map<String, dynamic> content) {
    final configured =
        content['homeDescription']?.toString().trim() ??
        'Выберите категорию, откройте профиль исполнителя и договоритесь о работе.';
    const combined =
        'Выберите категорию, откройте профиль исполнителя и договоритесь о работе. Если исполнителей нет, создайте заказ с подробным описанием задачи.';
    if (configured.isEmpty) return combined;
    if (configured.contains('Если нет исполнителей') &&
        !configured.contains('Выберите категорию')) {
      return 'Выберите категорию, откройте профиль исполнителя и договоритесь о работе. $configured';
    }
    return configured;
  }

  String _homeButtonText(Map<String, dynamic> content) {
    final configured = content['homeButtonText']?.toString().trim() ?? '';
    if (configured.isEmpty || configured.contains('Создать заказ')) {
      return 'Найти исполнителя';
    }
    return configured;
  }

  String _citySearchTitle(SettlementLocation settlement) {
    final city = settlement.city.trim();
    if (city.isEmpty) return 'Найти исполнителя';
    return 'Найти исполнителя: г. $city';
  }

  String _citySummarySubtitle(SettlementLocation settlement) {
    final city = settlement.city.trim();
    if (city.isEmpty) return 'Выберите категорию и исполнителя';
    return 'Показано по городу: г. $city';
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.profile['name']?.toString().trim();
    final settlement = SettlementLocation.fromProfileMap(widget.profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Исполнители'),
        actions: [
          const NotificationBellButton(),
          const ChatBadgeButton(),
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: UserAvatar(
              imageUrl: widget.profile['avatarUrl']?.toString(),
              name: widget.profile['name']?.toString(),
              radius: 16,
              bordered: true,
            ),
          ),
          IconButton(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateJob(settlement),
        label: const Text('Новый заказ'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<AppCatalogs>(
        future: _catalogsFuture,
        builder: (context, catalogsSnapshot) {
          if (!catalogsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = customerFilterCategories(catalogsSnapshot.data!);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestoreService().watchOpenJobs(),
            builder: (context, jobsSnapshot) {
              if (!jobsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final listingJobs =
                  jobsSnapshot.data!.docs
                      .map(Job.fromDoc)
                      .where(
                        (job) => executorListingMatchesFilters(
                          job,
                          selectedCategory: _selectedCategory,
                          selectedDate: _selectedDate,
                          preferredSettlement: settlement.isEmpty
                              ? null
                              : settlement,
                        ),
                      )
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final totalCount = listingJobs.length;

              return PremiumPageBody(
                maxWidth: 1400,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        PremiumLayout.isDesktop(context) &&
                        constraints.maxWidth > 900;
                    final cards = listingJobs
                        .map(
                          (job) => _ExecutorListingCard(
                            job: job,
                            onTap: () =>
                                _openExecutorListing(job.customerId, job),
                          ),
                        )
                        .toList();

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: CompactSummaryBar(
                            title: customerName?.isNotEmpty == true
                                ? 'Здравствуйте, $customerName'
                                : 'Исполнители',
                            subtitle: _citySummarySubtitle(settlement),
                            actions: [
                              PremiumStatChip(
                                label: 'Оставленных резюме',
                                value: '$totalCount',
                                light: true,
                              ),
                              PremiumStatChip(
                                label: 'Категория',
                                value: _selectedCategory == 'all'
                                    ? 'Все'
                                    : _selectedCategory,
                                light: true,
                              ),
                              if (settlement.city.trim().isNotEmpty)
                                PremiumStatChip(
                                  label: 'Город',
                                  value: settlement.city.trim(),
                                  light: true,
                                ),
                            ],
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverToBoxAdapter(
                          child:
                              StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>
                              >(
                                stream: FirestoreService()
                                    .watchContentSettings(),
                                builder: (context, contentSnapshot) {
                                  final content =
                                      contentSnapshot.data?.data() ?? {};
                                  return _HomeContentCard(
                                    title: _citySearchTitle(settlement),
                                    description: _homeDescription(content),
                                    buttonText: _homeButtonText(content),
                                    icon: Icons.search,
                                    onPressed: () => _pickCategory(categories),
                                    filters: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _buildCategoryButton(
                                          isWide: isWide,
                                          categories: categories,
                                        ),
                                        SizedBox(
                                          width: isWide ? 300 : double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: _pickDate,
                                            icon: const Icon(
                                              Icons.calendar_month_outlined,
                                            ),
                                            label: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _selectedDate == null
                                                        ? 'Дата выполнения'
                                                        : formatShortDate(
                                                            _selectedDate!,
                                                          ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_hasActiveFilters)
                                          TextButton.icon(
                                            onPressed: _clearFilters,
                                            icon: const Icon(Icons.close),
                                            label: const Text('Сбросить'),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        if (cards.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: PremiumEmptyState(
                              title: 'Исполнители не найдены',
                              subtitle:
                                  'Измените категорию или попробуйте позже.',
                              icon: Icons.person_search_outlined,
                            ),
                          )
                        else if (isWide)
                          SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 1.55,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => cards[index],
                              childCount: cards.length,
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final itemIndex = index ~/ 2;
                              if (index.isOdd) {
                                return const SizedBox(height: 12);
                              }
                              return cards[itemIndex];
                            }, childCount: cards.length * 2 - 1),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 96)),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeContentCard extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final IconData icon;
  final VoidCallback onPressed;
  final Widget filters;

  const _HomeContentCard({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.icon,
    required this.onPressed,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      accented: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? 'Как работает сервис' : title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(
                buttonText.isEmpty ? 'Найти исполнителя' : buttonText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          Text(
            'Фильтр исполнителей',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          filters,
        ],
      ),
    );
  }
}

class _ExecutorListingCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _ExecutorListingCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final city = job.cityDisplayName.trim().isNotEmpty
        ? job.cityDisplayName.trim()
        : job.city.trim();
    final description = job.description.trim();
    final title = job.category.trim().isNotEmpty
        ? job.category.trim()
        : job.title.trim().isNotEmpty
        ? job.title.trim()
        : 'Заявка исполнителя';

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirestoreService().getUserProfile(job.customerId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = data['name']?.toString().trim() ?? 'Исполнитель';
        final avatarUrl = data['avatarUrl']?.toString() ?? '';

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: PremiumPanel(
            accented: true,
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  imageUrl: avatarUrl,
                  name: name,
                  radius: 30,
                  bordered: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(name, style: Theme.of(context).textTheme.bodyMedium),
                      if (city.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          city,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.layers_outlined, size: 16),
                            label: Text(job.category),
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.payments_outlined,
                              size: 16,
                            ),
                            label: Text('${job.budget} KZT'),
                          ),
                          if (job.scheduledAt != null)
                            Chip(
                              avatar: const Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                              ),
                              label: Text(formatShortDate(job.scheduledAt!)),
                            ),
                          const Chip(
                            avatar: Icon(
                              Icons.assignment_ind_outlined,
                              size: 16,
                            ),
                            label: Text('Заявка исполнителя'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.person_search_outlined),
                          label: const Text('Открыть заявку'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
