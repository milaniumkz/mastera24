import 'package:flutter/material.dart';

import '../../models/job.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/premium_layout.dart';

class JobPreviewScreen extends StatelessWidget {
  final Job job;

  const JobPreviewScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заказ')),
      body: PremiumPageBody(
        maxWidth: 920,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumHeroBanner(
              eyebrow: job.category,
              title: job.title,
              subtitle: job.description,
              subtitleMaxLines: 6,
              stats: [
                PremiumStatChip(
                  label: 'Бюджет',
                  value: '${job.budget} KZT',
                  light: true,
                ),
                if (job.city.isNotEmpty)
                  PremiumStatChip(label: 'Город', value: job.city, light: true),
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
            const SizedBox(height: 16),
            PremiumPanel(
              accented: true,
              child: Text(
                'Это заказ другого пользователя. Здесь можно посмотреть детали. Управление доступно только автору заказа.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
