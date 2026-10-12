class AppConfig {
  static const String flavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'prod',
  );
  static const bool isProduction = flavor == 'prod';
  static const int bidFeeKzt = 0;
  static const String currency = 'KZT';
  static const String paymentSuccessUrl = String.fromEnvironment(
    'PAYMENT_SUCCESS_URL',
    defaultValue: 'https://mastera24.app/payment/success',
  );
  static const String paymentFailureUrl = String.fromEnvironment(
    'PAYMENT_FAILURE_URL',
    defaultValue: 'https://mastera24.app/payment/failure',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
  static const String fcmWebVapidKey = String.fromEnvironment(
    'FCM_WEB_VAPID_KEY',
    defaultValue: '',
  );

  static bool get isGoogleSignInConfigured => googleServerClientId.isNotEmpty;
}
