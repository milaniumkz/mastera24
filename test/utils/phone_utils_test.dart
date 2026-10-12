import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/utils/phone_utils.dart';

void main() {
  group('PhoneUtils.hiddenAuthEmailToPhone', () {
    test('extracts phone from hidden auth email', () {
      expect(
        PhoneUtils.hiddenAuthEmailToPhone('phone_77052597368@mastera42.kz'),
        '+7 (705) 259-73-68',
      );
    });

    test('returns null for unrelated email', () {
      expect(
        PhoneUtils.hiddenAuthEmailToPhone('user@example.com'),
        isNull,
      );
    });
  });

  group('PhoneUtils.normalize', () {
    test('returns empty string for empty input', () {
      expect(PhoneUtils.normalize(''), '');
    });

    test('converts 8-prefixed numbers to 7-prefixed E.164 local form', () {
      expect(PhoneUtils.normalize('8 (777) 123-45-67'), '77771234567');
    });

    test('converts 8-prefixed partial numbers immediately', () {
      expect(PhoneUtils.normalize('87'), '77');
    });

    test('prepends 7 to 10-digit numbers', () {
      expect(PhoneUtils.normalize('7771234567'), '77771234567');
    });

    test('truncates longer values to 11 digits', () {
      expect(PhoneUtils.normalize('+7 777 123 45 67 89'), '77771234567');
    });

  });

  group('PhoneUtils.normalizeLocal', () {
    test('extracts local digits from full +7 number', () {
      expect(PhoneUtils.normalizeLocal('+7 705 259 73 68'), '7052597368');
    });
  });

  group('PhoneUtils.format', () {
    test('returns +7 for empty value', () {
      expect(PhoneUtils.format(''), '+7');
    });

    test('formats partial numbers', () {
      expect(PhoneUtils.format('77771'), '+7 (777) 71');
    });

    test('formats full numbers', () {
      expect(PhoneUtils.format('87771234567'), '+7 (777) 123-45-67');
    });
  });

  test('PhoneInputFormatter always rewrites text to canonical phone format', () {
    final formatter = PhoneInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(text: '87771234567'),
    );

    expect(result.text, '(777) 123-45-67');
    expect(result.selection, const TextSelection.collapsed(offset: 15));
  });

  test('PhoneInputFormatter accepts pasted full +7 number in local field', () {
    final formatter = PhoneInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(
        text: '+7 705 259 73 68',
        selection: TextSelection.collapsed(offset: 16),
      ),
    );

    expect(result.text, '(705) 259-73-68');
    expect(result.selection, const TextSelection.collapsed(offset: 15));
  });

  test('PhoneInputFormatter keeps cursor near typed position', () {
    final formatter = PhoneInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(
        text: '7052',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );

    expect(result.text, '(705) 2');
    expect(result.selection, const TextSelection.collapsed(offset: 7));
  });
}
