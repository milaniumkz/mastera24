import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mastera_logo.dart';
import '../../widgets/premium_layout.dart';
import 'phone_auth_screen.dart';

class SignInScreen extends StatefulWidget {
  final AuthService? authService;

  const SignInScreen({super.key, this.authService});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final AuthService _authService;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogle();
    } catch (error) {
      setState(() {
        _error = AppErrorMapper.map(
          error,
          fallback: 'Не удалось выполнить вход через Google. Попробуйте позже.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.signInWithApple();
    } catch (error) {
      setState(() {
        _error = AppErrorMapper.map(
          error,
          fallback: 'Не удалось выполнить вход через Apple. Попробуйте позже.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDesktop = PremiumLayout.isDesktop(context);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isGoogleConfigured = AppConfig.isGoogleSignInConfigured;
    final canUseGoogle = !isAndroid || isGoogleConfigured;
    final canUseApple = !isAndroid;
    final authMethodsText = isAndroid
        ? isGoogleConfigured
              ? 'Доступны вход по номеру телефона и Google.'
              : 'Доступен вход по номеру телефона.'
        : 'Доступны вход по номеру телефона, Google и Apple.';

    final formPanel = PremiumPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MasteraLogo(fontSize: 22, compact: true),
            const SizedBox(height: 10),
            Text('Быстрый вход', style: textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(authMethodsText, style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1C4BA)),
                  ),
                  child: Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PhoneAuthScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.sms_rounded),
                label: Text(
                  _isLoading ? 'Подождите...' : 'Войти по номеру телефона',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading || !canUseGoogle
                    ? null
                    : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: const Text('Войти через Google'),
              ),
            ),
            if (isAndroid && !isGoogleConfigured) ...[
              const SizedBox(height: 10),
              Text(
                'Google вход отключен до настройки Firebase OAuth.',
                style: textTheme.bodySmall,
              ),
            ],
            if (canUseApple) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading || !canUseApple
                      ? null
                      : _signInWithApple,
                  icon: const Icon(Icons.apple_rounded),
                  label: const Text('Войти через Apple'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Платформа для заказчиков и мастеров. После входа вы автоматически продолжите в профиль роли.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: PremiumPageBody(
          maxWidth: isDesktop ? 1380 : 680,
          child: Center(
            child: SingleChildScrollView(
              child: isDesktop
                  ? PremiumSplitLayout(
                      primary: PremiumHeroBanner(
                        eyebrow: '',
                        title: 'Вход',
                        subtitle: 'Заказы, чаты и уведомления.',
                      ),
                      secondary: formPanel,
                    )
                  : formPanel,
            ),
          ),
        ),
      ),
    );
  }
}
