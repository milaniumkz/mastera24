import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/core/errors/app_error_mapper.dart';

void main() {
  group('AppErrorMapper.map', () {
    test('maps auth errors', () {
      expect(
        AppErrorMapper.map(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        'Неверный номер телефона или пароль.',
      );
      expect(
        AppErrorMapper.map(
          FirebaseAuthException(code: 'too-many-requests'),
        ),
        'Слишком много попыток. Повторите позже.',
      );
    });

    test('maps cloud functions errors', () {
      expect(
        AppErrorMapper.map(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'Denied',
          ),
        ),
        'Недостаточно прав для этого действия.',
      );
      expect(
        AppErrorMapper.map(
          FirebaseFunctionsException(
            code: 'failed-precondition',
            message: 'Платеж не настроен.',
          ),
        ),
        'Платеж не настроен.',
      );
    });

    test('maps firebase errors from firestore/storage', () {
      expect(
        AppErrorMapper.map(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        'Недостаточно прав для этого действия.',
      );
      expect(
        AppErrorMapper.map(
          FirebaseException(
            plugin: 'firebase_storage',
            code: 'failed-precondition',
            message: 'Нужно завершить профиль.',
          ),
        ),
        'Нужно завершить профиль.',
      );
    });

    test('maps platform and network errors', () {
      expect(
        AppErrorMapper.map(
          PlatformException(code: 'NOT_CONFIGURED'),
        ),
        'Функция пока не настроена для этой сборки.',
      );
      expect(
        AppErrorMapper.map(const SocketException('offline')),
        'Проверьте интернет и попробуйте снова.',
      );
    });

    test('maps text fallbacks and unknown errors', () {
      expect(
        AppErrorMapper.map(Exception('network timeout')),
        'Проверьте интернет и попробуйте снова.',
      );
      expect(
        AppErrorMapper.map(
          Exception('not_configured'),
          fallback: 'fallback',
        ),
        'Функция пока недоступна. Обратитесь в поддержку.',
      );
      expect(
        AppErrorMapper.map(
          Exception('other'),
          fallback: 'fallback',
        ),
        'fallback',
      );
    });
  });
}
