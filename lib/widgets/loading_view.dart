import 'package:flutter/material.dart';

import 'mastera_logo.dart';
import 'premium_layout.dart';

class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({super.key, this.message = 'Загружаем...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PremiumPageBody(
          maxWidth: 560,
          child: Center(
            child: PremiumPanel(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MasteraLogo(fontSize: 22, compact: true),
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 18),
                    Text(message),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
