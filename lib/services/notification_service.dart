import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_config.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/customer/job_detail_loader_screen.dart';
import '../screens/executor/executor_job_detail_screen.dart';
import '../screens/executor/executor_profile_view_screen.dart';
import '../models/job.dart';
import 'firestore_service.dart';
import 'navigator_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;
  final Set<String> _knownNotificationIds = <String>{};
  bool _notificationFeedPrimed = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!kIsWeb) {
      await _initLocalNotifications();
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessageTap(initialMessage);
    }
    await _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthStateChanged,
    );
    await _handleAuthStateChanged(FirebaseAuth.instance.currentUser);
  }

  Future<void> refreshTokenForCurrentUser() async {
    try {
      await _registerToken();
    } catch (_) {
      // Do not interrupt app navigation when push setup is unavailable.
    }
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _knownNotificationIds.clear();
    _notificationFeedPrimed = false;

    if (user == null) {
      return;
    }

    _notificationSubscription = FirestoreService()
        .watchUserNotifications(user.uid)
        .listen(_handleNotificationSnapshot);
  }

  void _handleNotificationSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!_notificationFeedPrimed) {
      for (final document in snapshot.docs) {
        _knownNotificationIds.add(document.id);
      }
      _notificationFeedPrimed = true;
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) {
        continue;
      }
      if (!_knownNotificationIds.add(change.doc.id)) {
        continue;
      }
      final data = change.doc.data();
      if (data == null) {
        continue;
      }
      _presentInAppNotification(notificationId: change.doc.id, data: data);
    }
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final data = Map<String, dynamic>.from(
          jsonDecode(payload) as Map<String, dynamic>,
        );
        handleNotificationPayload(data);
      },
    );
  }

  Future<void> _registerToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _requestPermissions();

    if (kIsWeb && AppConfig.fcmWebVapidKey.isEmpty) {
      return;
    }

    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? AppConfig.fcmWebVapidKey : null,
    );
    if (token == null) return;

    await FirestoreService().upsertUserPushToken(uid: user.uid, token: token);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        await FirestoreService().users.doc(user.uid).set({
          'apnsToken': apnsToken,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _presentInAppNotification({
    required String notificationId,
    required Map<String, dynamic> data,
  }) async {
    final payload = Map<String, dynamic>.from(data);
    payload['notificationId'] = notificationId;
    final title = payload['title']?.toString() ?? 'MASTERA 24';
    final body = payload['body']?.toString() ?? 'У вас новое уведомление.';

    if (kIsWeb) {
      _showSnackBar(title: title, body: body, payload: payload);
      return;
    }

    await _showForegroundNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> _showForegroundNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mastera24_channel',
      'Уведомления',
      channelDescription: 'Уведомления MASTERA 24',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(payload),
    );
  }

  void _showSnackBar({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) {
    final messenger = NavigatorService.scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        action: SnackBarAction(
          label: 'Открыть',
          onPressed: () {
            handleNotificationPayload(payload);
          },
        ),
      ),
    );
  }

  Future<void> _handleMessageTap(RemoteMessage message) async {
    await handleNotificationPayload(message.data);
  }

  Future<void> handleNotificationPayload(Map<String, dynamic> data) async {
    final notificationId = data['notificationId']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      await FirestoreService().markNotificationRead(notificationId);
    }

    final type = data['type'];

    if (type == 'chat_message') {
      final chatId = data['chatId'];
      final messageId = data['messageId'];
      if (chatId is String && chatId.isNotEmpty) {
        NavigatorService.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              title: 'Чат по заявке',
              highlightMessageId: messageId is String ? messageId : null,
            ),
          ),
        );
      }
      return;
    }

    if (type == 'new_bid') {
      final jobId = data['jobId'];
      final bidId = data['bidId'];
      if (bidId is String && bidId.isNotEmpty) {
        NavigatorService.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: bidId,
              title: 'Чат по заказу',
            ),
          ),
        );
        return;
      }
      if (jobId is String && jobId.isNotEmpty) {
        NavigatorService.push(
          MaterialPageRoute(
            builder: (_) => JobDetailLoaderScreen(
              jobId: jobId,
              highlightBidId: bidId is String ? bidId : null,
            ),
          ),
        );
      }
      return;
    }

    if (type == 'new_job') {
      final jobId = data['jobId'];
      final targetRole = data['targetRole']?.toString();
      if (jobId is String && jobId.isNotEmpty) {
        final jobSnap = await FirestoreService().jobs.doc(jobId).get();
        if (!jobSnap.exists) return;
        final job = Job.fromDoc(jobSnap);
        if (targetRole == 'executor') {
          NavigatorService.push(
            MaterialPageRoute(builder: (_) => ExecutorJobDetailScreen(job: job)),
          );
        } else {
          NavigatorService.push(
            MaterialPageRoute(
              builder: (_) => ExecutorProfileViewScreen(
                executorId: job.customerId,
                listingJob: job,
              ),
            ),
          );
        }
      }
      return;
    }

    if (type == 'bid_status') {
      final bidId = data['bidId'];
      if (bidId is String && bidId.isNotEmpty) {
        NavigatorService.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: bidId,
              title: 'Чат по заказу',
            ),
          ),
        );
      }
      return;
    }
  }
}
