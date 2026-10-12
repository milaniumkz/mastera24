import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/settlement_location.dart';

class OsmSettlementService {
  final http.Client _client;
  final Uri _baseUri;

  OsmSettlementService({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse('https://nominatim.openstreetmap.org');

  Future<List<SettlementLocation>> searchSettlements(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return [];
    }

    final uri = _baseUri.replace(
      path: '/search',
      queryParameters: {
        'q': normalized,
        'format': 'jsonv2',
        'addressdetails': '1',
        'countrycodes': 'kz',
        'accept-language': 'ru',
        'limit': '8',
        'dedupe': '1',
      },
    );

    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OSM search failed with ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! List) {
      return [];
    }

    final seen = <String>{};
    final results = <SettlementLocation>[];
    for (final item in payload) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final location = parseSettlement(item);
      if (location == null) {
        continue;
      }
      final key =
          '${location.city.toLowerCase()}|${location.region.toLowerCase()}';
      if (seen.add(key)) {
        results.add(location);
      }
    }
    return results;
  }

  SettlementLocation? parseSettlement(Map<String, dynamic> item) {
    final address = item['address'];
    if (address is! Map<String, dynamic>) {
      return null;
    }

    final city =
        address['city']?.toString().trim() ??
        address['town']?.toString().trim() ??
        address['village']?.toString().trim() ??
        address['hamlet']?.toString().trim() ??
        address['municipality']?.toString().trim() ??
        item['name']?.toString().trim() ??
        '';
    if (city.isEmpty) {
      return null;
    }

    final region =
        address['state']?.toString().trim() ??
        address['region']?.toString().trim() ??
        address['county']?.toString().trim() ??
        '';
    final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0;
    final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0;

    return SettlementLocation(
      city: city,
      displayName: item['display_name']?.toString().trim() ?? city,
      region: region,
      latitude: lat,
      longitude: lon,
      type: item['type']?.toString().trim() ?? '',
    );
  }
}
