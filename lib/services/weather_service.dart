import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/location_suggestion.dart';
import '../models/weather_data.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  static const _forecastHost = 'api.open-meteo.com';
  static const _geocodeHost = 'geocoding-api.open-meteo.com';
  final http.Client _client;

  Future<WeatherData> fetchWeather(String cityName) async {
    final location = await _resolveLocation(cityName);
    final weather = await _fetchForecast(location);
    return weather;
  }

  Future<WeatherData> fetchDefaultWeather() => fetchWeather(defaultCity);

  Future<List<LocationSuggestion>> searchLocations(
    String query, {
    int limit = 6,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <LocationSuggestion>[];
    }

    final uri = Uri.https(_geocodeHost, '/v1/search', {
      'name': trimmed,
      'count': limit.toString(),
      'language': 'en',
      'format': 'json',
    });
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw WeatherException('Location lookup failed (${response.statusCode})');
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    final results = jsonBody['results'] as List<dynamic>?;

    if (results == null) {
      return const <LocationSuggestion>[];
    }

    return results
        .map((entry) {
          final data = entry as Map<String, dynamic>;
          final latitude = data['latitude'] as num?;
          final longitude = data['longitude'] as num?;
          final name = data['name'] as String?;
          if (latitude == null || longitude == null || name == null) {
            return null;
          }
          return LocationSuggestion(
            name: name,
            country: data['country'] as String?,
            admin1: data['admin1'] as String?,
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
          );
        })
        .whereType<LocationSuggestion>()
        .toList(growable: false);
  }

  Future<WeatherData> fetchWeatherForSuggestion(
    LocationSuggestion suggestion,
  ) async {
    final location = _GeoLocation(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      name: suggestion.name,
      country: suggestion.country,
    );
    return _fetchForecast(location);
  }

  Future<_GeoLocation> _resolveLocation(String cityName) async {
    final matches = await searchLocations(cityName, limit: 1);
    if (matches.isEmpty) {
      throw WeatherException('City "$cityName" not found. Try another search.');
    }

    final suggestion = matches.first;

    return _GeoLocation(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      name: suggestion.name,
      country: suggestion.country,
    );
  }

  Future<WeatherData> _fetchForecast(_GeoLocation location) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,weather_code',
      'timezone': 'auto',
    });
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw WeatherException('Request failed (${response.statusCode})');
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherData.fromJson(
      jsonBody,
      city: location.name,
      country: location.country,
    );
  }
}

class _GeoLocation {
  const _GeoLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.country,
  });

  final double latitude;
  final double longitude;
  final String name;
  final String? country;
}
