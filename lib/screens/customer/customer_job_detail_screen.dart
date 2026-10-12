import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/bid_status.dart';
import '../../constants/job_status.dart';
import '../../models/bid.dart';
import '../../models/executor_review.dart';
import '../../models/job.dart';
import '../../models/settlement_location.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/rating_stars.dart';
import '../chat/chat_screen.dart';
import 'create_job_screen.dart';
import '../executor/executor_profile_view_screen.dart';
import '../reviews/review_editor_screen.dart';

List<Bid> visibleBidsForCustomer(Iterable<Bid> bids) {
  return bids.where((bid) => bid.status != BidStatus.pendingPayment).toList();
}

bool canCustomerReviewBid(String status) {
  return status == BidStatus.submitted || status == BidStatus.accepted;
}

class CustomerJobDetailScreen extends StatefulWidget {
  final Job job;
  final String? highlightBidId;

  const CustomerJobDetailScreen({
    super.key,
    required this.job,
    this.highlightBidId,
  });

  @override
  State<CustomerJobDetailScreen> createState() =>
      _CustomerJobDetailScreenState();
}

class _CustomerJobDetailScreenState extends State<CustomerJobDetailScreen> {
  final Map<String, GlobalKey> _bidKeys = {};
  bool _highlightedOnce = false;

  void _scrollToHighlight(String bidId) {
    if (_highlightedOnce) return;
    final key = _bidKeys[bidId];
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _highlightedOnce = true;
      }
    });
  }

  Future<void> _openEdit(Job job) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateJobScreen(
          existingJob: job,
          executorMode: job.isExecutorJob,
          initialSettlement: SettlementLocation(
            city: job.city,
            displayName: job.city,
            region: job.cityRegion,
            latitude: 0,
            longitude: 0,
            type: 'city',
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FirestoreService service, Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заказ?'),
        content: const Text(
          'Заказ будет скрыт из ленты. История откликов и чатов сохранится.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await service.deleteOpenJob(
        job.id,
        ownerId: FirebaseAuth.instance.currentUser?.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заказ скрыт.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось удалить заказ. Попробуйте снова.'),
        ),
      );
    }
  }

  Future<void> _openReviewEditor({
    required Bid bid,
    ExecutorReview? review,
  }) async {
    final executorSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(bid.executorId)
        .get();
    final executorName = executorSnap.data()?['name']?.toString() ?? '';
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewEditorScreen(
          bidId: bid.id,
          jobId: bid.jobId,
          executorId: bid.executorId,
          executorName: executorName,
          initialReview: review,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Заявка')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.watchJob(widget.job.id),
        builder: (context, jobSnapshot) {
          final job = jobSnapshot.hasData && jobSnapshot.data!.exists
              ? Job.fromDoc(jobSnapshot.data!)
              : widget.job;

          return PremiumPageBody(
            maxWidth: 1380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumHeroBanner(
                  eyebrow: '',
                  title: job.title,
                  subtitle: job.description,
                  darker: false,
                  subtitleMaxLines: 3,
                  stats: [
                    PremiumStatChip(
                      label: 'Категория',
                      value: job.category,
                      light: true,
                    ),
                    PremiumStatChip(
                      label: 'Бюджет',
                      value: '${job.budget} KZT',
                      light: true,
                    ),
                    if (job.city.isNotEmpty)
                      PremiumStatChip(
                        label: 'Город',
                        value: job.city,
                        light: true,
                      ),
                    if (job.scheduledAt != null)
                      PremiumStatChip(
                        label: 'Дата',
                        value: formatShortDate(job.scheduledAt!),
                        light: true,
                      ),
                    PremiumStatChip(
                      label: 'Статус',
                      value: job.status,
                      light: true,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: PremiumPanel(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: service.watchBidsForJob(job.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final bids = visibleBidsForCustomer(
                          snapshot.data!.docs.map(Bid.fromDoc),
                        );
                        final canManage = JobStatus.isOpen(job.status);
                        if (!canManage) {
                          return const PremiumEmptyState(
                            title: 'Заявка недоступна',
                            subtitle: '',
                            icon: Icons.delete_outline,
                          );
                        }
                        if (bids.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (canManage) ...[
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _openEdit(job),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Редактировать'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _confirmDelete(service, job),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                              ],
                              const Expanded(
                                child: PremiumEmptyState(
                                  title: 'Пока нет чатов',
                                  subtitle:
                                      'Когда исполнитель откроет чат по заказу, переписка появится здесь.',
                                  icon: Icons.chat_bubble_outline,
                                ),
                              ),
                            ],
                          );
                        }

                        if (widget.highlightBidId != null) {
                          _scrollToHighlight(widget.highlightBidId!);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (canManage) ...[
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _openEdit(job),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Редактировать'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _confirmDelete(service, job),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Удалить'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                            ],
                            Expanded(
                              child: ListView.separated(
                                itemCount: bids.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final bid = bids[index];
                                  final isHighlighted =
                                      bid.id == widget.highlightBidId;
                                  _bidKeys.putIfAbsent(
                                    bid.id,
                                    () => GlobalKey(),
                                  );

                                  return Card(
                                    key: _bidKeys[bid.id],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: isHighlighted
                                          ? BorderSide(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              width: 1.4,
                                            )
                                          : BorderSide.none,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: [
                                              Chip(
                                                label: Text(
                                                  'Цена: ${bid.price} KZT',
                                                ),
                                              ),
                                              const Chip(
                                                label: Text('Чат по заказу'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(bid.comment),
                                          const SizedBox(height: 14),
                                          OutlinedButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ExecutorProfileViewScreen(
                                                        executorId:
                                                            bid.executorId,
                                                        bid: bid,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Профиль исполнителя',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (canCustomerReviewBid(bid.status))
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: FilledButton.icon(
                                                    onPressed: () async {
                                                      await service
                                                          .ensureChatForBid(
                                                            bidId: bid.id,
                                                            jobId: bid.jobId,
                                                            customerId:
                                                                bid.customerId,
                                                            executorId:
                                                                bid.executorId,
                                                          );
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              ChatScreen(
                                                                chatId: bid.id,
                                                                title:
                                                                    'Чат по заявке',
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.chat_bubble_outline,
                                                    ),
                                                    label: const Text(
                                                      'Чат по заказу',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (canCustomerReviewBid(bid.status))
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                StreamBuilder<
                                                  DocumentSnapshot<
                                                    Map<String, dynamic>
                                                  >
                                                >(
                                                  stream: service
                                                      .watchReviewForBid(
                                                        bid.id,
                                                      ),
                                                  builder: (context, reviewSnap) {
                                                    final review =
                                                        reviewSnap.hasData &&
                                                            reviewSnap
                                                                .data!
                                                                .exists
                                                        ? ExecutorReview.fromDoc(
                                                            reviewSnap.data!,
                                                          )
                                                        : null;

                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        OutlinedButton.icon(
                                                          onPressed: () =>
                                                              _openReviewEditor(
                                                                bid: bid,
                                                                review: review,
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .reviews_outlined,
                                                          ),
                                                          label: Text(
                                                            review == null
                                                                ? 'Оставить отзыв'
                                                                : 'Изменить отзыв',
                                                          ),
                                                        ),
                                                        if (review != null) ...[
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Container(
                                                            width:
                                                                double.infinity,
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                              border: Border.all(
                                                                color: Theme.of(
                                                                  context,
                                                                ).dividerColor,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                RatingStars(
                                                                  rating: review
                                                                      .rating,
                                                                  size: 18,
                                                                ),
                                                                if (review
                                                                    .comment
                                                                    .trim()
                                                                    .isNotEmpty) ...[
                                                                  const SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Text(
                                                                    review
                                                                        .comment,
                                                                  ),
                                                                ],
                                                                if (review
                                                                    .photoUrls
                                                                    .isNotEmpty) ...[
                                                                  const SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Text(
                                                                    'Фото: ${review.photoUrls.length}',
                                                                    style: Theme.of(
                                                                      context,
                                                                    ).textTheme.bodySmall,
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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
