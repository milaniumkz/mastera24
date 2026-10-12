import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/loading_view.dart';
import '../admin/admin_home_screen.dart';
import '../customer/customer_home_screen.dart';
import '../executor/executor_home_screen.dart';
import 'role_setup_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final user = snapshot.data;
        if (user == null) {
          return const SignInScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().watchUserProfile(user.uid),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }

            if (!profileSnap.hasData || !profileSnap.data!.exists) {
              final initialPhone =
                  user.phoneNumber != null && user.phoneNumber!.isNotEmpty
                  ? PhoneUtils.format(user.phoneNumber!)
                  : PhoneUtils.hiddenAuthEmailToPhone(user.email);
              return RoleSetupScreen(
                uid: user.uid,
                initialPhone: initialPhone,
              );
            }

            final data = profileSnap.data!.data() ?? {};
            final role = data['role'] ?? 'customer';
            NotificationService().refreshTokenForCurrentUser();

            if (role == 'admin') {
              return const AdminHomeScreen();
            }

            if (role == 'executor') {
              return ExecutorHomeScreen(
                userId: user.uid,
                profile: data,
              );
            }

            return CustomerHomeScreen(userId: user.uid, profile: data);
          },
        );
      },
    );
  }
}
