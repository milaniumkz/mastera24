import 'package:flutter/material.dart';

import '../../core/errors/app_error_mapper.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/mastera_logo.dart';
import '../../widgets/premium_layout.dart';

class PhoneAuthScreen extends StatefulWidget {
  final AuthService? authService;

  const PhoneAuthScreen({super.key, this.authService});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  static const _defaultPhoneLocal = '(777) 777-77-77';

  late final AuthService _authService;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _phoneController.value = const TextEditingValue(
      text: _defaultPhoneLocal,
      selection: TextSelection.collapsed(offset: _defaultPhoneLocal.length),
    );
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (PhoneUtils.normalize(phone).length != 11) {
      setState(() => _error = 'Введите номер в формате +7 (###) ###-##-##.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Пароль должен быть не менее 6 символов.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _authService.signInWithPhonePassword(
          phoneNumber: phone,
          password: password,
        );
      } else {
        await _authService.registerWithPhonePassword(
          phoneNumber: phone,
          password: password,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorMapper.map(
          error,
          fallback: _isLogin
              ? 'Не удалось выполнить вход. Попробуйте позже.'
              : 'Не удалось создать аккаунт. Попробуйте позже.',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final phoneController = TextEditingController(text: _phoneController.text);
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    var isResetting = false;
    var isNewPasswordVisible = false;
    var isConfirmPasswordVisible = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isResetting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitReset() async {
              final phone = phoneController.text.trim();
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();

              if (PhoneUtils.normalize(phone).length != 11) {
                setDialogState(
                  () => dialogError =
                      'Введите номер в формате +7 (###) ###-##-##.',
                );
                return;
              }
              if (password.length < 6) {
                setDialogState(
                  () => dialogError = 'Пароль должен быть не менее 6 символов.',
                );
                return;
              }
              if (password != confirm) {
                setDialogState(() => dialogError = 'Пароли не совпадают.');
                return;
              }

              setDialogState(() {
                isResetting = true;
                dialogError = null;
              });

              try {
                await _authService.resetPhonePassword(
                  phoneNumber: phone,
                  newPassword: password,
                );
                if (!mounted || !dialogContext.mounted) return;
                _phoneController.text = phoneController.text;
                _passwordController.text = password;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Пароль обновлен. Теперь можно войти.'),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;
                setDialogState(() {
                  dialogError = AppErrorMapper.map(
                    error,
                    fallback:
                        'Не удалось восстановить пароль. Попробуйте позже.',
                  );
                  isResetting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Восстановление пароля'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Номер телефона',
                        prefixText: '+7 ',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: !isNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Новый пароль',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          tooltip: isNewPasswordVisible
                              ? 'Скрыть пароль'
                              : 'Показать пароль',
                          onPressed: () {
                            setDialogState(
                              () =>
                                  isNewPasswordVisible = !isNewPasswordVisible,
                            );
                          },
                          icon: Icon(
                            isNewPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Повторите пароль',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          tooltip: isConfirmPasswordVisible
                              ? 'Скрыть пароль'
                              : 'Показать пароль',
                          onPressed: () {
                            setDialogState(
                              () => isConfirmPasswordVisible =
                                  !isConfirmPasswordVisible,
                            );
                          },
                          icon: Icon(
                            isConfirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: isResetting ? null : submitReset,
                  child: Text(isResetting ? 'Сохраняем...' : 'Сменить пароль'),
                ),
              ],
            );
          },
        );
      },
    );

    // Dialog fields live only while the route is open; disposing immediately
    // after pop can race with the closing animation in Flutter Web/tests.
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDesktop = PremiumLayout.isDesktop(context);

    final formPanel = PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MasteraLogo(fontSize: 20, compact: true),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.line),
            ),
            child: Text(
              _isLogin
                  ? 'Введите номер телефона и пароль для входа.'
                  : 'Создайте пароль для входа по номеру телефона.',
              style: textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Номер телефона',
              hintText: '(705) 259-73-68',
              prefixText: '+7 ',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _isPasswordVisible
                    ? 'Скрыть пароль'
                    : 'Показать пароль',
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: Text(
              _isLoading
                  ? 'Подождите...'
                  : _isLogin
                  ? 'Войти'
                  : 'Зарегистрироваться',
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    });
                  },
            child: Text(
              _isLogin
                  ? 'Нет аккаунта? Регистрация'
                  : 'Уже есть аккаунт? Войти',
            ),
          ),
          if (_isLogin)
            TextButton(
              onPressed: _isLoading ? null : _showPasswordResetDialog,
              child: const Text('Забыли пароль? Восстановить'),
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Вход по номеру')),
      body: PremiumPageBody(
        maxWidth: isDesktop ? 1280 : 680,
        child: SingleChildScrollView(
          child: isDesktop
              ? PremiumSplitLayout(
                  primary: PremiumHeroBanner(
                    eyebrow: '',
                    title: _isLogin ? 'Вход по номеру' : 'Регистрация',
                    subtitle: _isLogin
                        ? 'Введите номер и пароль.'
                        : 'Создайте аккаунт.',
                  ),
                  secondary: formPanel,
                )
              : formPanel,
        ),
      ),
    );
  }
}
