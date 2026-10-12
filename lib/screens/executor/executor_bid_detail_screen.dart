import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/bid_status.dart';
import '../../services/firestore_service.dart';
import '../../widgets/premium_layout.dart';
import '../chat/chat_screen.dart';

bool canCallCustomer(String status) {
  return status == BidStatus.submitted || status == BidStatus.accepted;
}

bool canOpenCustomerChat(String status) {
  return status == BidStatus.submitted || status == BidStatus.accepted;
}

String buildPhoneCallPath(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (cleaned.isEmpty) return '';
  return cleaned.startsWith('+')
      ? cleaned
      : cleaned.startsWith('7')
      ? '+$cleaned'
      : cleaned;
}

class ExecutorBidDetailScreen extends StatelessWidget {
  final String bidId;

  const ExecutorBidDetailScreen({super.key, required this.bidId});

  Future<void> _callCustomer(BuildContext context, String phone) async {
    final path = buildPhoneCallPath(phone);
    if (path.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Не удалось открыть звонок на этом устройстве.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат по заказу')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().bids.doc(bidId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Отклик не найден.'));
          }

          final data = snapshot.data!.data() ?? {};
          final status = data['status'] ?? 'pending';
          final comment = data['comment'] ?? '';
          final price = data['price'] ?? 0;
          final customerId = data['customerId']?.toString() ?? '';

          return PremiumPageBody(
            maxWidth: 880,
            child: PremiumPanel(
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: customerId.isEmpty
                    ? null
                    : FirestoreService().getUserProfile(customerId),
                builder: (context, customerSnapshot) {
                  final customerData = customerSnapshot.data?.data() ?? {};
                  final customerName =
                      customerData['name']?.toString().trim() ?? '';
                  final customerPhone =
                      customerData['phone']?.toString().trim() ?? '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Чат по заказу',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Chip(label: Text('Цена: $price KZT')),
                          Chip(label: Text('Статус: $status')),
                          if (customerName.isNotEmpty)
                            Chip(label: Text('Заказчик: $customerName')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(comment.isEmpty ? 'Без комментария' : comment),
                      if (canCallCustomer(status) &&
                          customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () =>
                              _callCustomer(context, customerPhone),
                          icon: const Icon(Icons.call),
                          label: const Text('Позвонить заказчику'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          customerPhone,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (canOpenCustomerChat(status)) ...[
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () async {
                            await FirestoreService().ensureChatForBid(
                              bidId: bidId,
                              jobId: data['jobId']?.toString() ?? '',
                              customerId: data['customerId']?.toString() ?? '',
                              executorId: data['executorId']?.toString() ?? '',
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatId: bidId,
                                  title: 'Чат по заявке',
                                ),
                              ),
                            );
                          },
                          child: const Text('Чат по заказу'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
