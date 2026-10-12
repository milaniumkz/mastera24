import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/bid_status.dart';
import '../constants/job_status.dart';
import '../models/app_catalogs.dart';
import '../models/job.dart';
import '../models/settlement_location.dart';
import '../utils/job_fee_utils.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get jobs => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get bids => _db.collection('bids');
  CollectionReference<Map<String, dynamic>> get payments =>
      _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get chats =>
      _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get notifications =>
      _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get reviews =>
      _db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get settings =>
      _db.collection('settings');

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Map<String, dynamic> _profilePayload({
    required String role,
    required String name,
    required String phone,
    required SettlementLocation settlement,
    String avatarUrl = '',
    List<Map<String, dynamic>> portfolio = const [],
  }) {
    return {
      'role': role,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      ...settlement.toProfileMap(),
      'portfolio': portfolio,
      'fcmTokens': const <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> createUserProfile({
    required String uid,
    required String role,
    required String name,
    required String phone,
    required SettlementLocation settlement,
    String avatarUrl = '',
  }) async {
    await users.doc(uid).set({
      ..._profilePayload(
        role: role,
        name: name,
        phone: phone,
        settlement: settlement,
        avatarUrl: avatarUrl,
      ),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return users.doc(uid).get();
  }

  Future<DateTime?> getExecutorTariffAccessUntil(String uid) async {
    final snapshot = await getUserProfile(uid);
    final value = snapshot.data()?['executorTariffAccessUntil'];
    return value is Timestamp ? value.toDate() : null;
  }

  Future<bool> hasExecutorTariffAccess(String uid) async {
    final accessUntil = await getExecutorTariffAccessUntil(uid);
    return accessUntil != null && accessUntil.isAfter(DateTime.now());
  }

  Future<DateTime> grantExecutorTariffAccess(
    String uid, {
    Duration duration = const Duration(hours: 24),
  }) async {
    final accessUntil = DateTime.now().add(duration);
    await users.doc(uid).set({
      'executorTariffPaidAt': FieldValue.serverTimestamp(),
      'executorTariffAccessUntil': Timestamp.fromDate(accessUntil),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return accessUntil;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile(String uid) {
    return users.doc(uid).snapshots();
  }

  Future<String> createJob({
    required String title,
    required String description,
    required String category,
    required SettlementLocation settlement,
    required DateTime scheduledAt,
    required int budget,
    required int bidFeeKzt,
    required String customerId,
    String ownerRole = 'customer',
  }) async {
    final doc = await jobs.add({
      'title': title,
      'description': description,
      'category': category,
      ...settlement.toJobMap(),
      'scheduledAt': Timestamp.fromDate(_dateOnly(scheduledAt)),
      'budget': budget,
      'bidFeeKzt': bidFeeKzt,
      'customerId': customerId,
      'ownerRole': ownerRole,
      'status': JobStatus.open,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchJob(String jobId) {
    return jobs.doc(jobId).snapshots();
  }

  Future<void> updateJob({
    required String jobId,
    required String title,
    required String description,
    required String category,
    required SettlementLocation settlement,
    required DateTime scheduledAt,
    required int budget,
    required int bidFeeKzt,
  }) {
    return jobs.doc(jobId).update({
      'title': title,
      'description': description,
      'category': category,
      ...settlement.toJobMap(),
      'scheduledAt': Timestamp.fromDate(_dateOnly(scheduledAt)),
      'budget': budget,
      'bidFeeKzt': bidFeeKzt,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOpenJob(String jobId, {String? ownerId}) async {
    final jobDoc = await jobs.doc(jobId).get();
    if (!jobDoc.exists) return;
    if (ownerId != null && jobDoc.data()?['customerId'] != ownerId) {
      throw StateError('Cannot delete a job owned by another user.');
    }

    await jobs.doc(jobId).set({
      'status': JobStatus.cancelled,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCustomerJobs(String uid) {
    return jobs
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllJobs() {
    return jobs.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchExecutors() {
    return users.where('role', isEqualTo: 'executor').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOpenJobs() {
    return jobs
        .where('status', isEqualTo: JobStatus.open)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBidsForJob(String jobId) {
    return bids
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCustomerBids(
    String customerId,
  ) {
    return bids.where('customerId', isEqualTo: customerId).snapshots();
  }

  Future<String> createOrReuseBid({
    required String jobId,
    required String customerId,
    required String executorId,
    required int price,
    required String comment,
    String initialStatus = BidStatus.pendingPayment,
  }) async {
    final existing = await bids
        .where('jobId', isEqualTo: jobId)
        .where('executorId', isEqualTo: executorId)
        .limit(10)
        .get();

    for (final doc in existing.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? BidStatus.pendingPayment;
      if (!BidStatus.active.contains(status)) {
        continue;
      }
      if (initialStatus == BidStatus.submitted &&
          status == BidStatus.pendingPayment) {
        continue;
      }
      return doc.id;
    }

    final payload = <String, dynamic>{
      'jobId': jobId,
      'customerId': customerId,
      'executorId': executorId,
      'price': price,
      'comment': comment,
      'status': initialStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (initialStatus == BidStatus.submitted) {
      payload['submittedAt'] = FieldValue.serverTimestamp();
    }

    final doc = await bids.add(payload);
    return doc.id;
  }

  Future<int> getBidFeeKzt() async {
    final snapshot = await settings.doc('billing').get();
    final fee = (snapshot.data()?['bidFeeKzt'] as num?)?.toInt();
    return fee != null && fee > 0 ? fee : 0;
  }

  Future<AppCatalogs> getAppCatalogs() async {
    final snapshot = await settings.doc('catalogs').get();
    return AppCatalogs.fromSettings(snapshot.data());
  }

  Future<int> getBidFeeForCategory(String categoryName) async {
    final catalogs = await getAppCatalogs();
    return catalogs.bidFeeForCategory(categoryName);
  }

  Future<int> getBidFeeForJob(Job job) async {
    final catalogs = await getAppCatalogs();
    final legacyBidFeeKzt = await getBidFeeKzt();
    return resolveJobBidFeeKzt(
      job: job,
      catalogs: catalogs,
      legacyBidFeeKzt: legacyBidFeeKzt,
    );
  }

  Future<void> updateBidStatus(String bidId, String status) {
    return bids.doc(bidId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptBidAndCreateChat({
    required String bidId,
    required String jobId,
    required String customerId,
    required String executorId,
  }) async {
    final bidRef = bids.doc(bidId);
    final chatRef = chats.doc(bidId);
    await _db.runTransaction((transaction) async {
      final bidSnap = await transaction.get(bidRef);
      if (!bidSnap.exists) {
        throw StateError('Bid not found');
      }
      transaction.update(bidRef, {
        'status': BidStatus.accepted,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(chatRef, {
        'jobId': jobId,
        'bidId': bidId,
        'customerId': customerId,
        'executorId': executorId,
        'participantIds': [customerId, executorId],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> rejectBid(String bidId) {
    return bids.doc(bidId).update({
      'status': BidStatus.rejected,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createChatForBid({
    required String bidId,
    required String jobId,
    required String customerId,
    required String executorId,
  }) async {
    await ensureChatForBid(
      bidId: bidId,
      jobId: jobId,
      customerId: customerId,
      executorId: executorId,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatId) {
    return chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserChats(String uid) {
    return chats
        .where(
          Filter.or(
            Filter('customerId', isEqualTo: uid),
            Filter('executorId', isEqualTo: uid),
          ),
        )
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchChat(String chatId) {
    return chats.doc(chatId).snapshots();
  }

  Future<String> ensureChatForBid({
    required String bidId,
    required String jobId,
    required String customerId,
    required String executorId,
  }) async {
    final chatId = bidId;

    await _ensureChat(chatId, {
      'jobId': jobId,
      'bidId': bidId,
      'customerId': customerId,
      'executorId': executorId,
      'participantIds': [customerId, executorId],
    });

    return chatId;
  }

  Future<String> ensureDirectJobChat({
    required String jobId,
    required String customerId,
    required String executorId,
  }) async {
    final chatId = 'direct_${jobId}_$executorId';
    await _ensureChat(chatId, {
      'jobId': jobId,
      'bidId': '',
      'customerId': customerId,
      'executorId': executorId,
      'participantIds': [customerId, executorId],
      'type': 'direct_job',
    });

    return chatId;
  }

  Future<void> _ensureChat(String chatId, Map<String, dynamic> data) async {
    // Opening a conversation must preserve its messages and read state.
    await chats.doc(chatId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markChatRead(String chatId, String uid, Timestamp incomingAt) {
    return chats.doc(chatId).set({
      'readAt': {uid: incomingAt},
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? fileType,
  }) async {
    final chatRef = chats.doc(chatId);
    final chat = (await chatRef.get()).data();
    if (chat == null ||
        (chat['customerId'] != senderId && chat['executorId'] != senderId)) {
      throw StateError('Chat not found or unavailable');
    }
    final recipientId = chat['customerId'] == senderId
        ? chat['executorId'] as String
        : chat['customerId'] as String;
    final messageRef = chatRef.collection('messages').doc();
    final summaryText = text.trim().isNotEmpty
        ? text.trim()
        : imageUrl?.isNotEmpty == true
        ? 'Изображение'
        : fileName?.isNotEmpty == true
        ? 'Файл: $fileName'
        : 'Сообщение';

    final batch = _db.batch();
    batch.set(messageRef, {
      'senderId': senderId,
      'text': text.trim(),
      'imageUrl': imageUrl ?? '',
      'fileUrl': fileUrl ?? '',
      'fileName': fileName ?? '',
      'fileType': fileType ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(chatRef, {
      'lastMessageText': summaryText,
      'lastSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'incomingAt': {recipientId: FieldValue.serverTimestamp()},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchExecutorBids(
    String executorId,
  ) {
    return bids
        .where('executorId', isEqualTo: executorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBillingSettings() {
    return settings.doc('billing').snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCatalogSettings() {
    return settings.doc('catalogs').snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchContentSettings() {
    return settings.doc('content').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserNotifications(
    String uid,
  ) {
    return notifications
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchReviewForBid(
    String bidId,
  ) {
    return reviews.doc(bidId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchExecutorReviews(
    String executorId,
  ) {
    return reviews.where('executorId', isEqualTo: executorId).snapshots();
  }

  Future<void> upsertExecutorReview({
    required String bidId,
    required String jobId,
    required String customerId,
    required String customerName,
    required String customerAvatarUrl,
    required String executorId,
    required int rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    final reviewRef = reviews.doc(bidId);
    final reviewSnap = await reviewRef.get();

    await reviewRef.set({
      'bidId': bidId,
      'jobId': jobId,
      'customerId': customerId,
      'customerName': customerName,
      'customerAvatarUrl': customerAvatarUrl,
      'executorId': executorId,
      'rating': rating,
      'comment': comment,
      'photoUrls': photoUrls,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!reviewSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePortfolio({
    required String uid,
    required List<Map<String, dynamic>> portfolio,
  }) {
    return users.doc(uid).update({
      'portfolio': portfolio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addUserServiceCategory({
    required String uid,
    required String category,
  }) {
    final normalized = category.trim();
    if (normalized.isEmpty) {
      return Future.value();
    }
    return users.doc(uid).set({
      'serviceCategories': FieldValue.arrayUnion([normalized]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateExecutorResume({
    required String uid,
    required String category,
    required String description,
  }) {
    return users.doc(uid).set({
      'serviceCategories': FieldValue.arrayUnion([category.trim()]),
      'executorResume': description.trim(),
      'executorResumeCategory': category.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
    required String role,
    required SettlementLocation settlement,
    String avatarUrl = '',
    required List<Map<String, dynamic>> portfolio,
  }) {
    return users.doc(uid).set({
      ..._profilePayload(
        role: role,
        name: name,
        phone: phone,
        settlement: settlement,
        avatarUrl: avatarUrl,
        portfolio: portfolio,
      ),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotificationCategories({
    required String uid,
    required String role,
    required List<String> categories,
  }) {
    final normalized =
        categories
            .map((category) => category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return users.doc(uid).set({
      'notificationCategoriesByRole.$role': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertUserPushToken({
    required String uid,
    required String token,
  }) {
    return users.doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markNotificationRead(String notificationId) {
    return notifications.doc(notificationId).set({
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllNotificationsRead(String recipientId) async {
    final snapshot = await notifications
        .where('recipientId', isEqualTo: recipientId)
        .get();
    final batch = _db.batch();
    var hasUpdates = false;

    for (final doc in snapshot.docs) {
      if (doc.data()['readAt'] != null) continue;
      batch.set(doc.reference, {
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<void> markNotificationsReadByTypes({
    required String recipientId,
    required Set<String> types,
  }) async {
    if (types.isEmpty) return;

    final snapshot = await notifications
        .where('recipientId', isEqualTo: recipientId)
        .get();
    final batch = _db.batch();
    var hasUpdates = false;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['readAt'] != null) continue;
      final type = data['type']?.toString();
      if (!types.contains(type)) continue;

      batch.set(doc.reference, {
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<void> markChatNotificationsRead({
    required String recipientId,
    required String chatId,
  }) async {
    final snapshot = await notifications
        .where('recipientId', isEqualTo: recipientId)
        .get();
    final batch = _db.batch();
    var hasUpdates = false;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final payload = Map<String, dynamic>.from(data['data'] as Map? ?? {});
      final isTarget =
          data['readAt'] == null &&
          data['type'] == 'chat_message' &&
          payload['chatId'] == chatId;
      if (!isTarget) continue;

      batch.set(doc.reference, {
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<void> markJobConversationNotificationsRead({
    required String recipientId,
    required String jobId,
    required String bidId,
    required String chatId,
  }) async {
    final snapshot = await notifications
        .where('recipientId', isEqualTo: recipientId)
        .get();
    final batch = _db.batch();
    var hasUpdates = false;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['readAt'] != null) continue;

      final type = data['type']?.toString();
      final payload = Map<String, dynamic>.from(data['data'] as Map? ?? {});
      final matchesChat = type == 'chat_message' && payload['chatId'] == chatId;
      final matchesBid =
          type == 'new_bid' &&
          payload['jobId'] == jobId &&
          payload['bidId'] == bidId;
      final matchesBidStatus =
          type == 'bid_status' &&
          (payload['bidId'] == bidId || payload['jobId'] == jobId);
      if (!matchesChat && !matchesBid && !matchesBidStatus) continue;

      batch.set(doc.reference, {
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }
}
