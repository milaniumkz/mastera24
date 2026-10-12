import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/job.dart';
import '../../services/firestore_service.dart';
import '../../widgets/job_card.dart';
import '../../widgets/premium_layout.dart';
import 'customer_job_detail_screen.dart';

List<Job> activeJobsForOwnerRole(Iterable<Job> jobs, String ownerRole) {
  return jobs.where((job) => job.isOpen && job.ownerRole == ownerRole).toList();
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: _AllOrdersTab(service: service, userId: user.uid),
    );
  }
}

class _AllOrdersTab extends StatelessWidget {
  final FirestoreService service;
  final String userId;

  const _AllOrdersTab({required this.service, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchCustomerJobs(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final customerJobs = activeJobsForOwnerRole(
          snapshot.data!.docs.map(Job.fromDoc),
          'customer',
        );
        final executorJobs = activeJobsForOwnerRole(
          snapshot.data!.docs.map(Job.fromDoc),
          'executor',
        );

        if (customerJobs.isEmpty && executorJobs.isEmpty) {
          return const PremiumPageBody(
            child: PremiumEmptyState(
              title: 'Нет ваших заказов',
              subtitle: 'Созданные вами заявки появятся здесь.',
              icon: Icons.assignment_outlined,
            ),
          );
        }

        return PremiumPageBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
            children: [
              ...customerJobs.map(
                (job) => _MyJobCardWithRoleLabel(
                  job: job,
                  label: 'Ваш заказ как заказчик',
                ),
              ),
              ...executorJobs.map(
                (job) => _MyJobCardWithRoleLabel(
                  job: job,
                  label: 'Ваш заказ как исполнитель',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MyJobCardWithRoleLabel extends StatelessWidget {
  final Job job;
  final String label;

  const _MyJobCardWithRoleLabel({required this.job, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          JobCard(
            job: job,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerJobDetailScreen(job: job),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
