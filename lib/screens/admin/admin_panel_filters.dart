bool adminMatchesQuery(Iterable<String?> values, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }
  return values.any(
    (value) => (value ?? '').toLowerCase().contains(normalizedQuery),
  );
}

bool adminMatchesFilter(String value, String filter) {
  if (filter == 'all') {
    return true;
  }
  return value == filter;
}
