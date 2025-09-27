class LocationSuggestion {
  const LocationSuggestion({
    required this.name,
    this.country,
    this.admin1,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String? country;
  final String? admin1;
  final double latitude;
  final double longitude;

  String get displayName {
    final parts = [
      name,
      if (admin1 != null && admin1!.isNotEmpty) admin1,
      country,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}
