import 'package:flutter/material.dart';

import '../models/job.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatting.dart';
import 'premium_layout.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onBidTap;
  final int bidCount;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onBidTap,
    this.bidCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: PremiumPanel(
        accented: true,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 16),
                if (bidCount > 0) ...[
                  Tooltip(
                    message: onBidTap == null ? 'Отклики' : 'Чат по заказу',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onBidTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF97316)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mark_email_unread_outlined,
                                size: 16,
                                color: Color(0xFFEA580C),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$bidCount',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${job.budget} KZT',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.description,
              maxLines: PremiumLayout.isDesktop(context) ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.ink),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.layers_outlined, size: 16),
                  label: Text(job.category),
                ),
                if (job.city.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.location_on_outlined, size: 16),
                    label: Text(job.city),
                  ),
                if (job.scheduledAt != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: Text(formatShortDate(job.scheduledAt!)),
                  ),
                Chip(
                  avatar: const Icon(Icons.bolt_outlined, size: 16),
                  label: Text(job.status == 'open' ? 'Открыта' : job.status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
