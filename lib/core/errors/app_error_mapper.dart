import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AppErrorMapper {
  static String map(
    Object error, {
    String fallback = 'Не удалось выполнить действие. Попробуйте снова.',
  }) {
    if (error is FirebaseAuthException) {
      return _mapAuth(error, fallback: fallback);
    }
    if (error is FirebaseException) {
      return _mapFirebase(error, fallback: fallback);
    }
    if (error is FirebaseFunctionsException) {
      return _mapFunctions(error, fallback: fallback);
    }
    if (error is PlatformException) {
      return _mapPlatform(error, fallback: fallback);
    }
    final text = error.toString().toLowerCase();
    if (text.contains('network') || text.contains('socket')) {
      return 'Проверьте интернет и попробуйте снова.';
    }
    if (text.contains('timeout')) {
      return 'Сервис отвечает слишком долго. Повторите попытку.';
    }
    if (text.contains('not configured') || text.contains('not_configured')) {
      return 'Функция пока недоступна. Обратитесь в поддержку.';
    }
    return fallback;
  }

  static String _mapAuth(
    FirebaseAuthException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
        return 'Неверный номер телефона или пароль.';
      case 'user-not-found':
        return 'Аккаунт с таким номером не найден.';
      case 'email-already-in-use':
        return 'Этот номер уже зарегистрирован. Выполните вход.';
      case 'operation-not-allowed':
        return 'Способ входа пока не подключен.';
      case 'invalid-email':
        return 'Номер введён некорректно. Используйте формат +7 (###) ###-##-##.';
      case 'too-many-requests':
        return 'Слишком много попыток. Повторите позже.';
      case 'weak-password':
        return 'Пароль слишком простой. Минимум 6 символов.';
      case 'user-disabled':
        return 'Аккаунт временно отключён.';
      case 'network-request-failed':
        return 'Проверьте интернет и попробуйте снова.';
      case 'account-exists-with-different-credential':
        return 'Для этого аккаунта уже используется другой способ входа.';
      default:
        return fallback;
    }
  }

  static String _mapFunctions(
    FirebaseFunctionsException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Нужно заново войти в аккаунт.';
      case 'permission-denied':
        return 'Недостаточно прав для этого действия.';
      case 'not-found':
        return 'Данные не найдены или уже изменились.';
      case 'already-exists':
        return 'Такое действие уже выполнено.';
      case 'failed-precondition':
        return error.message?.isNotEmpty == true ? error.message! : fallback;
      case 'resource-exhausted':
        return 'Слишком много попыток. Повторите позже.';
      case 'unavailable':
        return 'Сервис временно недоступен. Попробуйте позже.';
      default:
        return error.message?.isNotEmpty == true ? error.message! : fallback;
    }
  }

  static String _mapFirebase(
    FirebaseException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'permission-denied':
        return 'Недостаточно прав для этого действия.';
      case 'not-found':
        return 'Данные не найдены или уже изменились.';
      case 'failed-precondition':
        return error.message?.isNotEmpty == true ? error.message! : fallback;
      case 'already-exists':
        return 'Такое действие уже выполнено.';
      case 'aborted':
        return 'Операция была прервана. Повторите попытку.';
      case 'unavailable':
        return 'Сервис временно недоступен. Попробуйте позже.';
      case 'network-request-failed':
        return 'Проверьте интернет и попробуйте снова.';
      default:
        return error.message?.isNotEmpty == true ? error.message! : fallback;
    }
  }

  static String _mapPlatform(
    PlatformException error, {
    required String fallback,
  }) {
    switch (error.code.toUpperCase()) {
      case 'IN_PROGRESS':
        return 'Операция уже выполняется.';
      case 'NOT_CONFIGURED':
        return 'Функция пока не настроена для этой сборки.';
      case 'CANCELLED':
      case 'CANCELED':
        return 'Действие отменено.';
      default:
        return error.message?.isNotEmpty == true ? error.message! : fallback;
    }
  }
}
