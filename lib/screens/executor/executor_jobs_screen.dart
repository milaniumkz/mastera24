import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_catalogs.dart';
import '../../models/job.dart';
import '../../models/settlement_location.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/job_card.dart';
import '../../widgets/premium_layout.dart';
import 'executor_job_detail_screen.dart';

class ExecutorJobsScreen extends StatefulWidget {
  final String currentUserId;
  final String profileName;
  final SettlementLocation? preferredSettlement;

  const ExecutorJobsScreen({
    super.key,
    required this.currentUserId,
    this.profileName = '',
    this.preferredSettlement,
  });

  @override
  State<ExecutorJobsScreen> createState() => _ExecutorJobsScreenState();
}

class _ExecutorJobsScreenState extends State<ExecutorJobsScreen> {
  late final FirestoreService _service;
  late final Future<AppCatalogs> _catalogsFuture;
  String _category = 'all';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _service = FirestoreService();
    _catalogsFuture = _service.getAppCatalogs();
  }

  String get _citySearchTitle {
    final city = widget.preferredSettlement?.city.trim() ?? '';
    if (city.isEmpty) return 'Найти заказчика';
    return 'Найти заказчика: г. $city';
  }

  String get _citySummarySubtitle {
    final city = widget.preferredSettlement?.city.trim() ?? '';
    if (city.isEmpty) return 'Выберите категорию и заказчика';
    return 'Показано по городу: г. $city';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppCatalogs>(
      future: _catalogsFuture,
      builder: (context, catalogsSnapshot) {
        final catalogs = catalogsSnapshot.data ?? AppCatalogs.defaults();
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.watchOpenJobs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var jobs = snapshot.data!.docs.map(Job.fromDoc).toList();
            if (_category != 'all') {
              jobs = jobs.where((job) => job.category == _category).toList();
            }
            if (_selectedDate != null) {
              jobs = jobs
                  .where(
                    (job) =>
                        job.scheduledAt != null &&
                        DateUtils.isSameDay(job.scheduledAt, _selectedDate),
                  )
                  .toList();
            }
            jobs = filterAvailableExecutorJobs(
              jobs,
              currentUserId: widget.currentUserId,
              preferredSettlement: widget.preferredSettlement,
            );
            jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final isWide =
                PremiumLayout.isDesktop(context) &&
                MediaQuery.sizeOf(context).width > 900;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: CompactSummaryBar(
                    title: widget.profileName.isNotEmpty
                        ? 'Здравствуйте, ${widget.profileName}'
                        : 'Заявки',
                    subtitle: _citySummarySubtitle,
                    actions: [
                      PremiumStatChip(
                        label: 'Заявок',
                        value: '${jobs.length}',
                        light: true,
                      ),
                      PremiumStatChip(
                        label: 'Категория',
                        value: _category == 'all' ? 'Все' : _category,
                        light: true,
                      ),
                      if (widget.preferredSettlement?.city.trim().isNotEmpty ==
                          true)
                        PremiumStatChip(
                          label: 'Город',
                          value: widget.preferredSettlement!.city.trim(),
                          light: true,
                        ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: PremiumPanel(
                    accented: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _citySearchTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: isWide ? 300 : double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openCategoryPicker(catalogs),
                                icon: const Icon(Icons.layers_outlined),
                                label: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _category == 'all'
                                            ? 'Все категории'
                                            : _category,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.expand_more),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 300 : double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedDate == null
                                            ? 'Дата выполнения'
                                            : formatShortDate(_selectedDate!),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_category != 'all' || _selectedDate != null)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _category = 'all';
                                  _selectedDate = null;
                                }),
                                icon: const Icon(Icons.close),
                                label: const Text('Сбросить'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (jobs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        widget.preferredSettlement?.isNotEmpty == true
                            ? 'В вашем городе пока нет открытых заявок.'
                            : 'Пока нет открытых заявок.',
                      ),
                    ),
                  )
                else if (isWide)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.34,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final job = jobs[index];
                        return JobCard(
                          job: job,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExecutorJobDetailScreen(job: job),
                              ),
                            );
                          },
                        );
                      }, childCount: jobs.length),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final itemIndex = index ~/ 2;
                        if (index.isOdd) {
                          return const SizedBox(height: 12);
                        }
                        final job = jobs[itemIndex];
                        return JobCard(
                          job: job,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExecutorJobDetailScreen(job: job),
                              ),
                            );
                          },
                        );
                      }, childCount: jobs.length * 2 - 1),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openCategoryPicker(AppCatalogs catalogs) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Найти заказчика'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.apps_outlined),
                title: const Text('Все категории'),
                trailing: _category == 'all' ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop('all'),
              ),
              ...catalogs.activeCategories.map(
                (category) => ListTile(
                  leading: const Icon(Icons.layers_outlined),
                  title: Text(category.name),
                  trailing: _category == category.name
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(category.name),
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
      ),
    );
    if (selected == null) return;
    setState(() => _category = selected);
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
}

List<Job> filterAvailableExecutorJobs(
  List<Job> jobs, {
  required String currentUserId,
  Set<String> executorUserIds = const {},
  SettlementLocation? preferredSettlement,
}) {
  return jobs.where((job) {
    if (!job.isOpen || job.isExecutorJob) {
      return false;
    }
    return jobMatchesSettlement(job, preferredSettlement);
  }).toList();
}

bool jobMatchesSettlement(Job job, SettlementLocation? settlement) {
  if (settlement == null || settlement.isEmpty) {
    return true;
  }

  final hasCoordinates =
      settlement.latitude != 0 &&
      settlement.longitude != 0 &&
      job.cityLat != 0 &&
      job.cityLon != 0;
  if (hasCoordinates) {
    final latDiff = (job.cityLat - settlement.latitude).abs();
    final lonDiff = (job.cityLon - settlement.longitude).abs();
    if (latDiff <= 0.05 && lonDiff <= 0.05) {
      return true;
    }
  }

  final preferredCity = settlement.city.trim().toLowerCase();
  final preferredRegion = settlement.region.trim().toLowerCase();
  final jobCity = job.city.trim().toLowerCase();
  final jobRegion = job.cityRegion.trim().toLowerCase();

  if (preferredCity.isEmpty || jobCity != preferredCity) {
    return false;
  }
  if (preferredRegion.isEmpty || jobRegion.isEmpty) {
    return true;
  }
  return jobRegion == preferredRegion;
}
