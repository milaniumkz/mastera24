import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web index and manifest contain production metadata', () async {
    final indexHtml = await File('web/index.html').readAsString();
    final manifest = jsonDecode(
      await File('web/manifest.json').readAsString(),
    ) as Map<String, dynamic>;

    expect(indexHtml, contains('<title>MASTERA 24</title>'));
    expect(indexHtml, contains('сервис для поиска мастеров'));
    expect(manifest['name'], 'MASTERA 24');
    expect(manifest['short_name'], 'MASTERA 24');
    expect(manifest['description'], contains('размещения заявок'));
  });
}
