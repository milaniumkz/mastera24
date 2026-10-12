import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth/auth_gate.dart';
import 'services/navigator_service.dart';
import 'theme/app_theme.dart';

class Mastera24App extends StatelessWidget {
  const Mastera24App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MASTERA 24',
      theme: AppTheme.light,
      navigatorKey: NavigatorService.key,
      scaffoldMessengerKey: NavigatorService.scaffoldMessengerKey,
      navigatorObservers: [NavigatorService.routeObserver],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      home: const AuthGate(),
    );
  }
}
