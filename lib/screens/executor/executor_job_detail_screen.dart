import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/bid_status.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../models/job.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/premium_layout.dart';
import '../chat/chat_screen.dart';

bool shouldBypassBidPayment({required bool isWeb, required int bidFeeKzt}) {
  return isWeb || bidFeeKzt <= 0;
}

bool hasActiveExecutorTariff(DateTime? accessUntil, DateTime now) {
  return accessUntil != null && accessUntil.isAfter(now);
}

class ExecutorJobDetailScreen extends StatefulWidget {
  final Job job;

  const ExecutorJobDetailScreen({super.key, required this.job});

  @override
  State<ExecutorJobDetailScreen> createState() =>
      _ExecutorJobDetailScreenState();
}

class _ExecutorJobDetailScreenState extends State<ExecutorJobDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final firestoreService = FirestoreService();
      final hasAccess = await _ensureTariffAccess(
        firestoreService: firestoreService,
        userId: user.uid,
      );
      if (!hasAccess) return;

      final price = int.tryParse(_priceController.text.trim()) ?? 0;

      final bidId = await firestoreService.createOrReuseBid(
        jobId: widget.job.id,
        customerId: widget.job.customerId,
        executorId: user.uid,
        price: price,
        comment: _commentController.text.trim(),
        initialStatus: BidStatus.submitted,
      );
      try {
        await firestoreService.ensureChatForBid(
          bidId: bidId,
          jobId: widget.job.id,
          customerId: widget.job.customerId,
          executorId: user.uid,
        );
      } catch (_) {
        // The bid itself is the primary action. Chat can be recreated later.
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Чат по заказу открыт.')));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: bidId, title: 'Чат по заказу'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMapper.map(
                error,
                fallback: 'Не удалось отправить отклик. Попробуйте позже.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callCustomerDirectly() async {
    if (_isCalling) return;
    setState(() => _isCalling = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final firestoreService = FirestoreService();
      final hasAccess = await _ensureTariffAccess(
        firestoreService: firestoreService,
        userId: user.uid,
      );
      if (!hasAccess) return;
      await _callCustomer(firestoreService);
    } finally {
      if (mounted) {
        setState(() => _isCalling = false);
      }
    }
  }

  Future<bool> _ensureTariffAccess({
    required FirestoreService firestoreService,
    required String userId,
  }) async {
    final accessUntil = await firestoreService.getExecutorTariffAccessUntil(
      userId,
    );
    if (hasActiveExecutorTariff(accessUntil, DateTime.now())) {
      return true;
    }
    if (!mounted) return false;

    final shouldPay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тариф исполнителя'),
        content: const Text(
          'Оплатите тариф, чтобы на 24 часа открыть отклики, чат и звонки по всем заявкам.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Оплатить тариф'),
          ),
        ],
      ),
    );
    if (shouldPay != true) return false;

    await firestoreService.grantExecutorTariffAccess(userId);
    if (!mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Тариф активирован на 24 часа.')),
    );
    return true;
  }

  Future<void> _callCustomer(FirestoreService service) async {
    final customerSnap = await service.getUserProfile(widget.job.customerId);
    final phone = customerSnap.data()?['phone']?.toString().trim() ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У заказчика не указан телефон.')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: '+$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть звонок.')));
  }

  @override
  void dispose() {
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryTitle = widget.job.category.trim().isNotEmpty
        ? widget.job.category.trim()
        : widget.job.title.trim().isNotEmpty
        ? widget.job.title.trim()
        : 'Заявка';
    final secondaryTitle =
        widget.job.title.trim().isNotEmpty &&
            widget.job.title.trim() != categoryTitle
        ? widget.job.title.trim()
        : '';

    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle)),
      body: PremiumPageBody(
        maxWidth: 1320,
        child: SingleChildScrollView(
          child: PremiumSplitLayout(
            primary: PremiumHeroBanner(
              eyebrow: secondaryTitle,
              title: categoryTitle,
              subtitle: widget.job.description,
              darker: false,
              subtitleMaxLines: 3,
              stats: [
                PremiumStatChip(
                  label: 'Категория',
                  value: widget.job.category,
                  light: true,
                ),
                PremiumStatChip(
                  label: 'Бюджет',
                  value: '${widget.job.budget} KZT',
                  light: true,
                ),
                if (widget.job.city.isNotEmpty)
                  PremiumStatChip(
                    label: 'Город',
                    value: widget.job.city,
                    light: true,
                  ),
                if (widget.job.scheduledAt != null)
                  PremiumStatChip(
                    label: 'Дата',
                    value: formatShortDate(widget.job.scheduledAt!),
                    light: true,
                  ),
              ],
            ),
            secondary: PremiumPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Чат по заказу',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 14),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ваша цена (KZT)',
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Введите цену'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Комментарий',
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Введите комментарий'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _isLoading || _isCalling
                            ? null
                            : () => _submitBid(),
                        icon: const Icon(Icons.send_outlined),
                        label: Text(
                          _isLoading ? 'Открываем...' : 'Чат по заказу',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isLoading || _isCalling
                            ? null
                            : _callCustomerDirectly,
                        icon: const Icon(Icons.call_outlined),
                        label: Text(_isCalling ? 'Звонок...' : 'Позвонить'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Чат и звонок работают отдельно. В чате можно предложить цену.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
