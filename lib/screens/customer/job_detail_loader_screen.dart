import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/job.dart';
import '../../services/firestore_service.dart';
import 'customer_job_detail_screen.dart';

class JobDetailLoaderScreen extends StatelessWidget {
  final String jobId;
  final String? highlightBidId;

  const JobDetailLoaderScreen({
    super.key,
    required this.jobId,
    this.highlightBidId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заявка')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirestoreService().jobs.doc(jobId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Заявка не найдена.'));
          }

          final job = Job.fromDoc(snapshot.data!);
          return CustomerJobDetailScreen(
            job: job,
            highlightBidId: highlightBidId,
          );
        },
      ),
    );
  }
}
