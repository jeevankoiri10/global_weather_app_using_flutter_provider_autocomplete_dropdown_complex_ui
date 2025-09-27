// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kathmandu_weather/models/weather_data.dart';
import 'package:kathmandu_weather/screens/weather_screen.dart';
import 'package:kathmandu_weather/services/weather_service.dart';
import 'package:kathmandu_weather/providers/weather_provider.dart';

void main() {
  testWidgets('Shows loading indicator while fetching weather', (tester) async {
    final service = _FakeWeatherService();
    await tester.pumpWidget(
      ChangeNotifierProvider<WeatherProvider>(
        create: (_) => WeatherProvider(service: service),
        child: const MaterialApp(home: WeatherScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('weather_loader')), findsOneWidget);
  });
}

class _FakeWeatherService extends WeatherService {
  _FakeWeatherService() : super();

  @override
  Future<WeatherData> fetchWeather(String cityName) async {
    return _completer.future;
  }

  final Completer<WeatherData> _completer = Completer<WeatherData>();
}
