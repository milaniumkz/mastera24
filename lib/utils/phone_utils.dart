import 'package:flutter/services.dart';

class PhoneUtils {
  static String? hiddenAuthEmailToPhone(String? email) {
    if (email == null || email.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'^phone_(\d{11})@(mastera42\.kz|mastera24\.app)$',
      caseSensitive: false,
    ).firstMatch(email.trim());
    if (match == null) {
      return null;
    }

    return format(match.group(1)!);
  }

  static String normalizeLocal(String value) {
    final raw = value.trim();
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '';
    }

    if (raw.contains('+') && (digits.startsWith('7') || digits.startsWith('8'))) {
      digits = digits.substring(1);
    } else if (digits.startsWith('8')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('7') && digits.length >= 11) {
      digits = digits.substring(1);
    }

    return digits.length > 10 ? digits.substring(0, 10) : digits;
  }

  static String normalize(String value) {
    final localDigits = normalizeLocal(value);
    if (localDigits.isEmpty) {
      return '';
    }
    return '7$localDigits';
  }

  static String format(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) {
      return '+7';
    }

    final localDigits = normalized.startsWith('7')
        ? normalized.substring(1)
        : normalized;
    final local = localDigits.length > 10
        ? localDigits.substring(0, 10)
        : localDigits;
    final buffer = StringBuffer('+7');

    if (local.isNotEmpty) {
      buffer.write(' (');
      final areaEnd = local.length < 3 ? local.length : 3;
      buffer.write(local.substring(0, areaEnd));
    }
    if (local.length >= 3) {
      buffer.write(') ');
      final firstEnd = local.length < 6 ? local.length : 6;
      buffer.write(local.substring(3, firstEnd));
    }
    if (local.length >= 6) {
      buffer.write('-');
      final secondEnd = local.length < 8 ? local.length : 8;
      buffer.write(local.substring(6, secondEnd));
    }
    if (local.length >= 8) {
      buffer.write('-');
      final thirdEnd = local.length < 10 ? local.length : 10;
      buffer.write(local.substring(8, thirdEnd));
    }

    return buffer.toString();
  }

  static String formatLocal(String value) {
    final local = normalizeLocal(value);
    if (local.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    if (local.isNotEmpty) {
      buffer.write('(');
      final areaEnd = local.length < 3 ? local.length : 3;
      buffer.write(local.substring(0, areaEnd));
    }
    if (local.length >= 3) {
      buffer.write(') ');
      final firstEnd = local.length < 6 ? local.length : 6;
      buffer.write(local.substring(3, firstEnd));
    }
    if (local.length >= 6) {
      buffer.write('-');
      final secondEnd = local.length < 8 ? local.length : 8;
      buffer.write(local.substring(6, secondEnd));
    }
    if (local.length >= 8) {
      buffer.write('-');
      final thirdEnd = local.length < 10 ? local.length : 10;
      buffer.write(local.substring(8, thirdEnd));
    }

    return buffer.toString();
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  int _countDigits(String value, int endOffset) {
    final limit = endOffset.clamp(0, value.length);
    return value
        .substring(0, limit)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
  }

  int _selectionForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 1) {
      return formatted.length >= 2 ? 2 : formatted.length;
    }

    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        seenDigits++;
        if (seenDigits == digitCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = PhoneUtils.formatLocal(newValue.text);
    final hasValidSelection = newValue.selection.extentOffset >= 0;
    if (!hasValidSelection) {
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    final digitsBeforeCursor = _countDigits(
      newValue.text,
      newValue.selection.extentOffset,
    );
    final selectionOffset = _selectionForDigitCount(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}
