class UserProfile {
  final String uid;
  final String role;
  final String name;
  final String phone;
  final String avatarUrl;
  final String city;
  final String cityRegion;

  UserProfile({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.avatarUrl,
    required this.city,
    required this.cityRegion,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      role: data['role'] ?? 'customer',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      city: data['city'] ?? '',
      cityRegion: data['cityRegion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'city': city,
      'cityRegion': cityRegion,
    };
  }
}
