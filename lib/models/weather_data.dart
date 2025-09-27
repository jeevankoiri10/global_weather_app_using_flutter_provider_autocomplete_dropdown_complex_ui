class WeatherData {
  const WeatherData({
    required this.city,
    this.country,
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    this.observationTime,
  });

  final String city;
  final String? country;
  final String description;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final DateTime? observationTime;

  factory WeatherData.fromJson(
    Map<String, dynamic> json, {
    required String city,
    String? country,
  }) {
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw WeatherException('Missing current weather payload');
    }

    final temp = current['temperature_2m'] as num?;
    final feelsLike = current['apparent_temperature'] as num?;
    final humidity = current['relative_humidity_2m'] as num?;
    final wind = current['wind_speed_10m'] as num?;
    final code =
        current['weather_code'] as int? ?? current['weathercode'] as int?;
    final time = current['time'] as String?;

    if (temp == null || feelsLike == null || humidity == null || wind == null) {
      throw WeatherException('Missing weather metrics');
    }

    final description = mapWeatherCodeToDescription(code);

    return WeatherData(
      city: city,
      country: country,
      description: description,
      temperature: temp.toDouble(),
      feelsLike: feelsLike.toDouble(),
      humidity: humidity.toInt(),
      windSpeed: wind.toDouble(),
      weatherCode: code ?? -1,
      observationTime: time != null ? DateTime.tryParse(time) : null,
    );
  }
}

class WeatherException implements Exception {
  const WeatherException(this.message);
  final String message;

  @override
  String toString() => 'WeatherException: $message';
}

String mapWeatherCodeToDescription(int? code) {
  if (code == null) {
    return 'Unknown conditions';
  }

  const descriptions = <int, String>{
    0: 'Clear sky',
    1: 'Mainly clear',
    2: 'Partly cloudy',
    3: 'Overcast',
    45: 'Fog',
    48: 'Depositing rime fog',
    51: 'Light drizzle',
    53: 'Moderate drizzle',
    55: 'Dense drizzle',
    56: 'Light freezing drizzle',
    57: 'Dense freezing drizzle',
    61: 'Slight rain',
    63: 'Moderate rain',
    65: 'Heavy rain',
    66: 'Light freezing rain',
    67: 'Heavy freezing rain',
    71: 'Slight snow fall',
    73: 'Moderate snow fall',
    75: 'Heavy snow fall',
    77: 'Snow grains',
    80: 'Slight rain showers',
    81: 'Moderate rain showers',
    82: 'Violent rain showers',
    85: 'Slight snow showers',
    86: 'Heavy snow showers',
    95: 'Thunderstorm',
    96: 'Thunderstorm with slight hail',
    99: 'Thunderstorm with heavy hail',
  };

  return descriptions[code] ?? 'Unknown conditions';
}
