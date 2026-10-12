class SettlementLocation {
  final String city;
  final String displayName;
  final String region;
  final double latitude;
  final double longitude;
  final String type;

  const SettlementLocation({
    required this.city,
    required this.displayName,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  factory SettlementLocation.fromProfileMap(Map<String, dynamic> data) {
    return SettlementLocation(
      city: data['city']?.toString().trim() ?? '',
      displayName:
          data['cityDisplayName']?.toString().trim() ??
          data['city']?.toString().trim() ??
          '',
      region: data['cityRegion']?.toString().trim() ?? '',
      latitude: (data['cityLat'] as num?)?.toDouble() ?? 0,
      longitude: (data['cityLon'] as num?)?.toDouble() ?? 0,
      type: data['cityType']?.toString().trim() ?? '',
    );
  }

  factory SettlementLocation.fromJobMap(Map<String, dynamic> data) {
    return SettlementLocation(
      city: data['city']?.toString().trim() ?? '',
      displayName:
          data['cityDisplayName']?.toString().trim() ??
          data['city']?.toString().trim() ??
          '',
      region: data['cityRegion']?.toString().trim() ?? '',
      latitude: (data['cityLat'] as num?)?.toDouble() ?? 0,
      longitude: (data['cityLon'] as num?)?.toDouble() ?? 0,
      type: data['cityType']?.toString().trim() ?? '',
    );
  }

  bool get isEmpty => city.isEmpty;
  bool get isNotEmpty => city.isNotEmpty;

  String get shortLabel => region.isEmpty ? city : '$city, $region';

  Map<String, dynamic> toProfileMap() {
    return {
      'city': city,
      'cityDisplayName': displayName,
      'cityRegion': region,
      'cityLat': latitude,
      'cityLon': longitude,
      'cityType': type,
    };
  }

  Map<String, dynamic> toJobMap() {
    return {
      'city': city,
      'cityDisplayName': displayName,
      'cityRegion': region,
      'cityLat': latitude,
      'cityLon': longitude,
      'cityType': type,
    };
  }
}
