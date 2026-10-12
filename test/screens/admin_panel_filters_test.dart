import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/screens/admin/admin_panel_filters.dart';

void main() {
  test('adminMatchesQuery matches by lowercase substring', () {
    expect(adminMatchesQuery(['Дмитрий', '+7 777 777 77 77'], 'дмит'), isTrue);
    expect(adminMatchesQuery(['executor', 'active'], 'blocked'), isFalse);
  });

  test('adminMatchesFilter supports all wildcard and exact values', () {
    expect(adminMatchesFilter('active', 'all'), isTrue);
    expect(adminMatchesFilter('active', 'active'), isTrue);
    expect(adminMatchesFilter('active', 'blocked'), isFalse);
  });
}
