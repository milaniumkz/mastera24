import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/services/osm_settlement_service.dart';

void main() {
  test(
    'parseSettlement extracts settlement and region from nominatim payload',
    () {
      final service = OsmSettlementService();

      final location = service.parseSettlement({
        'lat': '43.238949',
        'lon': '76.889709',
        'type': 'city',
        'display_name': 'Алматы, Казахстан',
        'address': {'city': 'Алматы', 'state': 'Алматинская область'},
      });

      expect(location, isNotNull);
      expect(location!.city, 'Алматы');
      expect(location.region, 'Алматинская область');
      expect(location.latitude, 43.238949);
    },
  );
}
