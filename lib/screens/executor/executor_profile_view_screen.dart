import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/bid_status.dart';
import '../../models/bid.dart';
import '../../models/executor_review.dart';
import '../../models/job.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/executor_reviews_section.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/safe_network_image.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';
import '../media/portfolio_carousel_screen.dart';
import '../reviews/review_editor_screen.dart';

class ExecutorProfileViewScreen extends StatelessWidget {
  final String executorId;
  final Bid? bid;
  final Job? listingJob;

  const ExecutorProfileViewScreen({
    super.key,
    required this.executorId,
    this.bid,
    this.listingJob,
  });

  Future<void> _callExecutor(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: '+$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть звонок.')));
  }

  Future<void> _openChat(BuildContext context, Bid bid) async {
    final service = FirestoreService();
    await service.ensureChatForBid(
      bidId: bid.id,
      jobId: bid.jobId,
      customerId: bid.customerId,
      executorId: bid.executorId,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: bid.id, title: 'Чат по заявке'),
      ),
    );
  }

  Future<void> _openListingChat(BuildContext context, Job listingJob) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final service = FirestoreService();
    final chatId = await service.ensureDirectJobChat(
      jobId: listingJob.id,
      customerId: currentUser.uid,
      executorId: executorId,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chatId, title: 'Чат по заказу'),
      ),
    );
  }

  Future<void> _openReviewEditor(
    BuildContext context, {
    required Bid bid,
    required String executorName,
    ExecutorReview? review,
  }) async {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(listingJob == null ? 'Профиль исполнителя' : 'Заявка'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(executorId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Профиль не найден.'));
          }

          final data = snapshot.data!.data() ?? {};
          final portfolio = (data['portfolio'] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final portfolioPhotos = _flattenPortfolioPhotos(portfolio);
          final name = data['name']?.toString() ?? 'Без имени';
          final phone = data['phone']?.toString() ?? '';
          final city = listingJob?.cityDisplayName.trim().isNotEmpty == true
              ? listingJob!.cityDisplayName.trim()
              : listingJob?.city.trim().isNotEmpty == true
              ? listingJob!.city.trim()
              : data['city']?.toString() ?? '';
          final avatarUrl = data['avatarUrl']?.toString() ?? '';
          final profileCategories =
              (data['serviceCategories'] as List<dynamic>? ?? const [])
                  .map((value) => value.toString().trim())
                  .where((value) => value.isNotEmpty)
                  .toList();
          final categories = [
            if (listingJob?.category.trim().isNotEmpty == true)
              listingJob!.category.trim(),
            ...profileCategories.where(
              (category) => category != listingJob?.category.trim(),
            ),
          ];
          final description = _buildExecutorDescription(
            data,
            portfolio,
            categories,
            listingJob: listingJob,
          );
          final currentUser = FirebaseAuth.instance.currentUser;

          return PremiumPageBody(
            maxWidth: 920,
            child: ListView(
              children: [
                if (listingJob != null) ...[
                  PremiumHeroBanner(
                    eyebrow: 'Заявка исполнителя',
                    title: listingJob!.category.trim().isNotEmpty
                        ? listingJob!.category.trim()
                        : 'Заявка',
                    subtitle: listingJob!.description,
                    darker: false,
                    subtitleMaxLines: 6,
                    stats: [
                      PremiumStatChip(
                        label: 'Бюджет',
                        value: '${listingJob!.budget} KZT',
                        light: true,
                      ),
                      if (city.isNotEmpty)
                        PremiumStatChip(
                          label: 'Город',
                          value: city,
                          light: true,
                        ),
                      if (listingJob!.scheduledAt != null)
                        PremiumStatChip(
                          label: 'Дата',
                          value: formatShortDate(listingJob!.scheduledAt!),
                          light: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                PremiumPanel(
                  accented: true,
                  child: Row(
                    children: [
                      UserAvatar(
                        imageUrl: avatarUrl,
                        name: name,
                        radius: 34,
                        bordered: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(phone),
                            ],
                            if (city.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(city),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (listingJob == null) ...[
                  const SizedBox(height: 16),
                  PremiumPanel(
                    accented: true,
                    child: _ExecutorDescriptionSection(
                      categories: categories,
                      description: description,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PremiumPanel(
                  accented: true,
                  child: bid == null
                      ? _CustomerContactLookupSection(
                          customerId: currentUser?.uid ?? '',
                          executorId: executorId,
                          executorName: name,
                          onCall: phone.isEmpty
                              ? null
                              : () => _callExecutor(context, phone),
                          onPublicChat: listingJob == null
                              ? null
                              : () => _openListingChat(context, listingJob!),
                          onChat: (matchedBid) =>
                              _openChat(context, matchedBid),
                          onReview: (matchedBid, review) => _openReviewEditor(
                            context,
                            bid: matchedBid,
                            executorName: name,
                            review: review,
                          ),
                        )
                      : _BidContactSection(
                          bid: bid!,
                          executorName: name,
                          onCall: phone.isEmpty
                              ? null
                              : () => _callExecutor(context, phone),
                          onChat: () => _openChat(context, bid!),
                          onReview: (review) => _openReviewEditor(
                            context,
                            bid: bid!,
                            executorName: name,
                            review: review,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                PremiumPanel(
                  accented: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Наглядные работы',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (portfolioPhotos.isEmpty)
                        const Text('Пока нет фото работ.')
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: portfolioPhotos.length,
                          itemBuilder: (context, index) {
                            final photo = portfolioPhotos[index];
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PortfolioCarouselScreen(
                                      images: photo.gallery,
                                      initialIndex: photo.initialIndex,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.line),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: SafeNetworkImage(
                                        imageUrl: photo.imageUrl,
                                        width: double.infinity,
                                        height: 112,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            photo.title.isEmpty
                                                ? 'Работа'
                                                : photo.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          if (photo.description
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              photo.description.trim(),
                                              maxLines: 5,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          else
                                            const Text(
                                              'Описание не добавлено.',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PremiumPanel(
                  accented: true,
                  child: ExecutorReviewsSection(
                    executorId: executorId,
                    title: 'Отзывы заказчиков',
                    emptyText: 'Пока нет отзывов от заказчиков.',
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

class _ExecutorDescriptionSection extends StatelessWidget {
  final List<String> categories;
  final String description;

  const _ExecutorDescriptionSection({
    required this.categories,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Описание исполнителя',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (categories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map((category) => Chip(label: Text(category)))
                .toList(),
          ),
        if (categories.isNotEmpty) const SizedBox(height: 10),
        Text(
          description.isEmpty
              ? 'Исполнитель пока не добавил описание работ.'
              : description,
        ),
      ],
    );
  }
}

class _CustomerContactLookupSection extends StatelessWidget {
  final String customerId;
  final String executorId;
  final String executorName;
  final VoidCallback? onCall;
  final VoidCallback? onPublicChat;
  final ValueChanged<Bid> onChat;
  final void Function(Bid bid, ExecutorReview? review) onReview;

  const _CustomerContactLookupSection({
    required this.customerId,
    required this.executorId,
    required this.executorName,
    required this.onCall,
    required this.onPublicChat,
    required this.onChat,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (customerId.isEmpty) {
      return _PublicContactSection(onCall: onCall, onChat: onPublicChat);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().watchCustomerBids(customerId),
      builder: (context, snapshot) {
        final bids =
            (snapshot.data?.docs ?? const [])
                .map(Bid.fromDoc)
                .where((bid) => bid.executorId == executorId)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final matchedBid = bids.isEmpty ? null : bids.first;

        if (matchedBid == null) {
          return _PublicContactSection(onCall: onCall, onChat: onPublicChat);
        }

        return _BidContactSection(
          bid: matchedBid,
          executorName: executorName,
          onCall: onCall,
          onChat: () => onChat(matchedBid),
          onReview: (review) => onReview(matchedBid, review),
        );
      },
    );
  }
}

class _PublicContactSection extends StatelessWidget {
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  const _PublicContactSection({required this.onCall, this.onChat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Связь с исполнителем',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Позвонить и открыть чат можно сразу. В чате можно предложить цену.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Позвонить'),
            ),
            OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Чат по заказу'),
            ),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.reviews_outlined),
              label: const Text('Оставить отзыв'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BidContactSection extends StatelessWidget {
  final Bid bid;
  final String executorName;
  final VoidCallback? onCall;
  final VoidCallback onChat;
  final ValueChanged<ExecutorReview?> onReview;

  const _BidContactSection({
    required this.bid,
    required this.executorName,
    required this.onCall,
    required this.onChat,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final canReview =
        bid.status == BidStatus.submitted || bid.status == BidStatus.accepted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Чат по заказу', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Цена: ${bid.price} KZT')),
            Chip(label: Text('Статус: ${bid.status}')),
          ],
        ),
        if (bid.comment.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(bid.comment.trim()),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Позвонить'),
            ),
            OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Чат по заказу'),
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirestoreService().watchReviewForBid(bid.id),
              builder: (context, snapshot) {
                final review = snapshot.hasData && snapshot.data!.exists
                    ? ExecutorReview.fromDoc(snapshot.data!)
                    : null;
                return OutlinedButton.icon(
                  onPressed: canReview ? () => onReview(review) : null,
                  icon: const Icon(Icons.reviews_outlined),
                  label: Text(
                    review == null ? 'Оставить отзыв' : 'Изменить отзыв',
                  ),
                );
              },
            ),
          ],
        ),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().watchReviewForBid(bid.id),
          builder: (context, snapshot) {
            final review = snapshot.hasData && snapshot.data!.exists
                ? ExecutorReview.fromDoc(snapshot.data!)
                : null;
            if (review == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(rating: review.rating, size: 18),
                  if (review.comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(review.comment.trim()),
                  ],
                  if (review.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Фото в отзыве: ${review.photoUrls.length}'),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PortfolioPhoto {
  final String title;
  final String description;
  final String imageUrl;
  final List<String> gallery;
  final int initialIndex;

  const _PortfolioPhoto({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.gallery,
    required this.initialIndex,
  });
}

List<_PortfolioPhoto> _flattenPortfolioPhotos(
  List<Map<String, dynamic>> portfolio,
) {
  final photos = <_PortfolioPhoto>[];
  for (final item in portfolio) {
    final images =
        (item['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        ((item['imageUrl'] as String?)?.isNotEmpty == true
            ? [item['imageUrl'].toString()]
            : <String>[]);
    for (var index = 0; index < images.length; index++) {
      photos.add(
        _PortfolioPhoto(
          title: item['title']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          imageUrl: images[index],
          gallery: images,
          initialIndex: index,
        ),
      );
    }
  }
  return photos;
}

String _buildExecutorDescription(
  Map<String, dynamic> profile,
  List<Map<String, dynamic>> portfolio,
  List<String> categories, {
  Job? listingJob,
}) {
  final listingDescription = listingJob?.description.trim() ?? '';
  if (listingDescription.isNotEmpty) return listingDescription;

  final resume = profile['executorResume']?.toString().trim() ?? '';
  if (resume.isNotEmpty) return resume;

  final descriptions = portfolio
      .map((item) => item['description']?.toString().trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
  if (descriptions.isNotEmpty) {
    return descriptions.join('\n\n');
  }
  if (categories.isNotEmpty) {
    return 'Выполняет работы по категориям: ${categories.join(', ')}.';
  }
  return '';
}
