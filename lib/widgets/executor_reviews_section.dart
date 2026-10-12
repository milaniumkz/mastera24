import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/executor_review.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatting.dart';
import 'rating_stars.dart';
import 'safe_network_image.dart';
import 'user_avatar.dart';
import '../screens/media/portfolio_carousel_screen.dart';

class ExecutorReviewsSection extends StatelessWidget {
  final String executorId;
  final String title;
  final String emptyText;

  const ExecutorReviewsSection({
    super.key,
    required this.executorId,
    this.title = 'Отзывы',
    this.emptyText = 'Пока нет отзывов.',
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchExecutorReviews(executorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = sortExecutorReviews(
          snapshot.data!.docs.map(ExecutorReview.fromDoc),
        );
        final average = averageExecutorRating(reviews);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            if (reviews.isEmpty)
              Text(emptyText)
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(
                    label: Text('Рейтинг: ${average.toStringAsFixed(1)}'),
                  ),
                  Chip(label: Text('Отзывов: ${reviews.length}')),
                ],
              ),
              const SizedBox(height: 14),
              ...reviews.map((review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExecutorReviewCard(review: review),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _ExecutorReviewCard extends StatelessWidget {
  final ExecutorReview review;

  const _ExecutorReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                imageUrl: review.customerAvatarUrl,
                name: review.customerName,
                radius: 22,
                bordered: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName.isEmpty
                          ? 'Заказчик'
                          : review.customerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    RatingStars(rating: review.rating, size: 18),
                  ],
                ),
              ),
              Text(
                formatShortDate(review.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment.trim()),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(review.photoUrls.length, (index) {
                final url = review.photoUrls[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PortfolioCarouselScreen(
                          images: review.photoUrls,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SafeNetworkImage(
                      imageUrl: url,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
