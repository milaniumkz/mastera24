import 'package:flutter/material.dart';

import '../../core/errors/app_error_mapper.dart';
import '../../models/settlement_location.dart';
import '../../services/firestore_service.dart';
import '../../services/osm_settlement_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/settlement_picker_form_field.dart';

class RoleSetupScreen extends StatefulWidget {
  final String uid;
  final String? initialPhone;
  final FirestoreService? firestoreService;
  final SettlementLocation? initialSettlement;
  final OsmSettlementService? settlementService;

  const RoleSetupScreen({
    super.key,
    required this.uid,
    this.initialPhone,
    this.firestoreService,
    this.initialSettlement,
    this.settlementService,
  });

  @override
  State<RoleSetupScreen> createState() => _RoleSetupScreenState();
}

class _RoleSetupScreenState extends State<RoleSetupScreen> {
  static const _defaultPhoneLocal = '(777) 777-77-77';

  late final FirestoreService _firestoreService;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _role = 'customer';
  SettlementLocation? _settlement;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    _settlement = widget.initialSettlement;
    if (widget.initialPhone == null) {
      _phoneController.value = const TextEditingValue(
        text: _defaultPhoneLocal,
        selection: TextSelection.collapsed(offset: _defaultPhoneLocal.length),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _firestoreService.createUserProfile(
        uid: widget.uid,
        role: _role,
        name: _nameController.text.trim(),
        phone:
            widget.initialPhone ??
            PhoneUtils.format(_phoneController.text.trim()),
        settlement: _settlement!,
      );
    } catch (error) {
      setState(() {
        _error = AppErrorMapper.map(
          error,
          fallback: 'Не удалось сохранить профиль. Попробуйте снова.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDesktop = PremiumLayout.isDesktop(context);

    final formPanel = PremiumPanel(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Кто вы?', style: textTheme.headlineSmall),
          SizedBox(height: isDesktop ? 16 : 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ChoiceChip(
                label: const Text('Заказчик'),
                selected: _role == 'customer',
                onSelected: (_) => setState(() => _role = 'customer'),
              ),
              ChoiceChip(
                label: const Text('Исполнитель'),
                selected: _role == 'executor',
                onSelected: (_) => setState(() => _role = 'executor'),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 18),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Имя'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите имя' : null,
                ),
                SizedBox(height: isDesktop ? 16 : 14),
                if (widget.initialPhone == null)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      hintText: '(705) 259-73-68',
                      prefixText: '+7 ',
                    ),
                    validator: (value) =>
                        PhoneUtils.normalize(value ?? '').length != 11
                        ? 'Введите телефон в формате +7 (###) ###-##-##'
                        : null,
                  )
                else
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
                        Text('Номер телефона', style: textTheme.labelLarge),
                        const SizedBox(height: 6),
                        Text(widget.initialPhone!),
                      ],
                    ),
                  ),
                SizedBox(height: isDesktop ? 16 : 14),
                SettlementPickerFormField(
                  initialValue: _settlement,
                  searchService: widget.settlementService,
                  onSelected: (value) {
                    setState(() => _settlement = value);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 14),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          SizedBox(height: isDesktop ? 16 : 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _save,
              child: Text(_isLoading ? 'Сохраняем...' : 'Продолжить'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: PremiumPageBody(
        maxWidth: isDesktop ? 1280 : 680,
        child: SingleChildScrollView(
          child: isDesktop
              ? PremiumSplitLayout(
                  primary: PremiumHeroBanner(
                    eyebrow: '',
                    title: 'Профиль',
                    subtitle: 'Заполните профиль и продолжайте.',
                    stats: [
                      PremiumStatChip(
                        label: 'Роль',
                        value: _role == 'customer' ? 'Заказчик' : 'Исполнитель',
                      ),
                      PremiumStatChip(
                        label: 'Профиль',
                        value: widget.initialPhone == null
                            ? 'Новый'
                            : 'Подтвержден',
                      ),
                      PremiumStatChip(
                        label: 'Город',
                        value: _settlement?.city ?? 'Не выбран',
                      ),
                    ],
                  ),
                  secondary: formPanel,
                )
              : formPanel,
        ),
      ),
    );
  }
}
