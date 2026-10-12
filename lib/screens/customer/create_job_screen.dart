import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_catalogs.dart';
import '../../models/job.dart';
import '../../models/settlement_location.dart';
import '../../services/firestore_service.dart';
import '../../services/osm_settlement_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/settlement_picker_form_field.dart';

class CreateJobScreen extends StatefulWidget {
  final FirestoreService? firestoreService;
  final String? currentUserId;
  final SettlementLocation? initialSettlement;
  final OsmSettlementService? settlementService;
  final Job? existingJob;
  final bool executorMode;

  const CreateJobScreen({
    super.key,
    this.firestoreService,
    this.currentUserId,
    this.initialSettlement,
    this.settlementService,
    this.existingJob,
    this.executorMode = false,
  });

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  late final FirestoreService _firestoreService;
  late final Future<AppCatalogs> _catalogsFuture;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  String? _category;
  SettlementLocation? _settlement;
  late DateTime _scheduledAt;
  bool _isLoading = false;

  bool get _isEditing => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    _catalogsFuture = _firestoreService.getAppCatalogs();
    final existingJob = widget.existingJob;
    if (existingJob != null) {
      _descriptionController.text = existingJob.description;
      _budgetController.text = existingJob.budget.toString();
      _category = existingJob.category;
    }
    _scheduledAt = DateUtils.dateOnly(
      existingJob?.scheduledAt ?? DateTime.now(),
    );
    _settlement =
        widget.initialSettlement ??
        (existingJob == null
            ? null
            : SettlementLocation(
                city: existingJob.city,
                displayName: existingJob.city,
                region: existingJob.cityRegion,
                latitude: 0,
                longitude: 0,
                type: 'city',
              ));
  }

  Future<void> _pickScheduledAt() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      locale: const Locale('ru'),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _scheduledAt = DateUtils.dateOnly(selected);
    });
  }

  Future<void> _save(AppCatalogs catalogs) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final budget = int.tryParse(_budgetController.text) ?? 0;
    final category = _category ?? catalogs.activeCategories.first.name;
    final settlement = _settlement!;
    final title = category;

    if (_isEditing) {
      await _firestoreService.updateJob(
        jobId: widget.existingJob!.id,
        title: title,
        description: _descriptionController.text.trim(),
        category: category,
        settlement: settlement,
        scheduledAt: _scheduledAt,
        budget: budget,
        bidFeeKzt: catalogs.bidFeeForCategory(category),
      );
    } else {
      final userId =
          widget.currentUserId ?? FirebaseAuth.instance.currentUser!.uid;
      await _firestoreService.createJob(
        title: title,
        description: _descriptionController.text.trim(),
        category: category,
        settlement: settlement,
        scheduledAt: _scheduledAt,
        budget: budget,
        bidFeeKzt: catalogs.bidFeeForCategory(category),
        customerId: userId,
        ownerRole: widget.executorMode ? 'executor' : 'customer',
      );
      if (widget.executorMode) {
        await _firestoreService.updateExecutorResume(
          uid: userId,
          category: category,
          description: _descriptionController.text.trim(),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = PremiumLayout.isDesktop(context);
    final pageTitle = _isEditing ? 'Редактировать заказ' : 'Новый заказ';
    final submitLabel = _isEditing ? 'Сохранить изменения' : 'Создать заказ';
    final descriptionLabel = widget.executorMode
        ? 'Резюме: что вы умеете делать'
        : 'Что нужно сделать';
    final descriptionHint = widget.executorMode
        ? 'Напишите опыт, навыки, какие работы выполняете.'
        : 'Опишите задачу, сроки и важные детали.';

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: PremiumPageBody(
        maxWidth: isDesktop ? 1280 : 680,
        child: FutureBuilder<AppCatalogs>(
          future: _catalogsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final catalogs = snapshot.data!;
            final categories = catalogs.activeCategories;

            if (categories.isNotEmpty &&
                !_matchesCategory(categories, _category)) {
              _category = categories.first.name;
            }

            final selectedCategory = _category ?? '';

            final formPanel = PremiumPanel(
              padding: EdgeInsets.all(isDesktop ? 24 : 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory.isEmpty
                          ? null
                          : selectedCategory,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.name,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    SizedBox(height: isDesktop ? 16 : 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: isDesktop ? 5 : 4,
                      decoration: InputDecoration(
                        labelText: descriptionLabel,
                        hintText: descriptionHint,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Заполните описание'
                          : null,
                    ),
                    SizedBox(height: isDesktop ? 16 : 14),
                    InkWell(
                      key: const ValueKey('scheduledDateField'),
                      onTap: _isLoading ? null : _pickScheduledAt,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата выполнения',
                          suffixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        child: Text(formatShortDate(_scheduledAt)),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 16 : 14),
                    if (widget.initialSettlement != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Населенный пункт',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(_settlement?.city ?? ''),
                            if (_settlement?.region.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _settlement!.region,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Берется из профиля. Изменить можно в профиле.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      SettlementPickerFormField(
                        initialValue: _settlement,
                        searchService: widget.settlementService,
                        labelText: 'Населенный пункт',
                        onSelected: (value) {
                          setState(() => _settlement = value);
                        },
                      ),
                    SizedBox(height: isDesktop ? 16 : 14),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Бюджет (KZT)',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Введите бюджет'
                          : null,
                    ),
                    SizedBox(height: isDesktop ? 24 : 18),
                    FilledButton(
                      onPressed: _isLoading ? null : () => _save(catalogs),
                      child: Text(_isLoading ? 'Сохраняем...' : submitLabel),
                    ),
                  ],
                ),
              ),
            );

            return SingleChildScrollView(
              child: isDesktop
                  ? PremiumSplitLayout(
                      primary: PremiumHeroBanner(
                        eyebrow: '',
                        title: _isEditing
                            ? 'Редактирование заказа'
                            : 'Новый заказ',
                        subtitle: _isEditing
                            ? 'Обновите параметры заказа и сохраните изменения.'
                            : 'Выберите категорию, город и укажите бюджет.',
                        stats: [
                          PremiumStatChip(
                            label: 'Категория',
                            value: selectedCategory.isEmpty
                                ? '—'
                                : selectedCategory,
                          ),
                          PremiumStatChip(
                            label: 'Город',
                            value: _settlement?.city ?? 'Не выбран',
                          ),
                          PremiumStatChip(
                            label: 'Дата',
                            value: formatShortDate(_scheduledAt),
                          ),
                        ],
                      ),
                      secondary: formPanel,
                    )
                  : formPanel,
            );
          },
        ),
      ),
    );
  }

  bool _matchesCategory(List<ServiceCategory> categories, String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }
    return categories.any((category) => category.name == value);
  }
}
