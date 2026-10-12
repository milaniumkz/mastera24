import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_catalogs.dart';

class AdminService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchJobs() {
    return _db
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPayments() {
    return _db
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBids() {
    return _db
        .collection('bids')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchChats() {
    return _db
        .collection('chats')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications() {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> setUserStatus(String uid, String status) {
    return _db.collection('users').doc(uid).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserRole(String uid, String role) {
    return _db.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setJobStatus(String jobId, String status) {
    return _db.collection('jobs').doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setBidStatus(String bidId, String status) {
    return _db.collection('bids').doc(bidId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBidFee(int fee) {
    return _db.collection('settings').doc('billing').set({
      'bidFeeKzt': fee,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCatalogSettings() {
    return _db.collection('settings').doc('catalogs').snapshots();
  }

  Future<void> updateCatalogs({
    required List<ServiceCategory> categories,
    required List<String> cities,
  }) {
    return _db.collection('settings').doc('catalogs').set({
      'categories': categories.map((category) => category.toMap()).toList(),
      'cities': cities,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchContentSettings() {
    return _db.collection('settings').doc('content').snapshots();
  }

  Future<void> updateHomeContent({
    required String title,
    required String description,
    required String buttonText,
  }) {
    return _db.collection('settings').doc('content').set({
      'homeTitle': title,
      'homeDescription': description,
      'homeButtonText': buttonText,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> refundPayment({required String paymentId, int? amount}) async {
    final callable = _functions.httpsCallable('refundPayment');
    await callable.call({'paymentId': paymentId, 'amount': amount});
  }
}
