class ServiceCategory {
  final String id;
  final String name;
  final int bidFeeKzt;
  final bool isActive;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.bidFeeKzt,
    this.isActive = true,
  });

  factory ServiceCategory.fromMap(
    Map<String, dynamic> data, {
    required String fallbackId,
  }) {
    final name = data['name']?.toString().trim() ?? '';
    return ServiceCategory(
      id: data['id']?.toString().trim().isNotEmpty == true
          ? data['id'].toString().trim()
          : fallbackId,
      name: name,
      bidFeeKzt: (data['bidFeeKzt'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  ServiceCategory copyWith({
    String? id,
    String? name,
    int? bidFeeKzt,
    bool? isActive,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      bidFeeKzt: bidFeeKzt ?? this.bidFeeKzt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bidFeeKzt': bidFeeKzt,
      'isActive': isActive,
    };
  }
}

class AppCatalogs {
  static const List<ServiceCategory> fallbackCategories = [
    ServiceCategory(id: 'repair', name: 'Ремонт', bidFeeKzt: 300),
    ServiceCategory(id: 'cleaning', name: 'Клининг', bidFeeKzt: 200),
    ServiceCategory(id: 'delivery', name: 'Доставка', bidFeeKzt: 150),
    ServiceCategory(id: 'it', name: 'IT', bidFeeKzt: 500),
  ];

  static const List<String> fallbackCities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Караганда',
    'Актобе',
    'Атырау',
    'Тараз',
    'Павлодар',
  ];

  final List<ServiceCategory> categories;
  final List<String> cities;

  const AppCatalogs({required this.categories, required this.cities});

  factory AppCatalogs.defaults() {
    return const AppCatalogs(
      categories: fallbackCategories,
      cities: fallbackCities,
    );
  }

  factory AppCatalogs.fromSettings(Map<String, dynamic>? data) {
    final rawCategories = data?['categories'] as List<dynamic>?;
    final parsedCategories = rawCategories
        ?.asMap()
        .entries
        .map(
          (entry) => ServiceCategory.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            fallbackId: 'category_${entry.key}',
          ),
        )
        .where((category) => category.name.isNotEmpty)
        .toList();
    final rawCities = data?['cities'] as List<dynamic>?;
    final parsedCities = rawCities
        ?.map((city) => city.toString().trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList();

    return AppCatalogs(
      categories: parsedCategories == null || parsedCategories.isEmpty
          ? fallbackCategories
          : parsedCategories,
      cities: parsedCities == null || parsedCities.isEmpty
          ? fallbackCities
          : parsedCities,
    );
  }

  List<ServiceCategory> get activeCategories {
    final filtered = categories.where((category) => category.isActive).toList();
    return filtered.isEmpty ? categories : filtered;
  }

  int bidFeeForCategory(String categoryName) {
    final normalized = categoryName.trim().toLowerCase();
    for (final category in categories) {
      if (category.name.trim().toLowerCase() == normalized) {
        return category.bidFeeKzt;
      }
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'categories': categories.map((category) => category.toMap()).toList(),
      'cities': cities,
    };
  }
}
