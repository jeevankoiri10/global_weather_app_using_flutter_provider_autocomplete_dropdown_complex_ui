import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/weather_provider.dart';
import 'screens/weather_screen.dart';

class KathmanduWeatherApp extends StatelessWidget {
  const KathmanduWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: MaterialApp(
        title: 'Global Weather Explorer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          scaffoldBackgroundColor: Colors.transparent,
          useMaterial3: true,
        ),
        home: const WeatherScreen(),
      ),
    );
  }
}
