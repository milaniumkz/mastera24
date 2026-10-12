import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/bid_status.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';

class ExecutorBidsScreen extends StatelessWidget {
  const ExecutorBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final service = FirestoreService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchExecutorBids(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bids = snapshot.data!.docs;
        if (bids.isEmpty) {
          return const Center(child: Text('Нет чатов по заказам.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bids.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = bids[index].data();
            final status = data['status'] ?? 'pending';
            final price = data['price'] ?? 0;
            final comment = data['comment'] ?? '';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Цена: $price KZT'),
                    const SizedBox(height: 8),
                    Text(comment),
                    const SizedBox(height: 8),
                    Text('Статус: $status'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (status == BidStatus.submitted ||
                            status == BidStatus.accepted)
                          FilledButton.icon(
                            onPressed: () async {
                              await service.ensureChatForBid(
                                bidId: bids[index].id,
                                jobId: data['jobId']?.toString() ?? '',
                                customerId: data['customerId']?.toString() ?? '',
                                executorId: data['executorId']?.toString() ?? '',
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: bids[index].id,
                                    title: 'Чат по заявке',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Чат по заказу'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
