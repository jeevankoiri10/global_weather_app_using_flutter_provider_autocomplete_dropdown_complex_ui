import 'package:flutter/material.dart';

import '../models/weather_data.dart';

class WeatherDetails extends StatelessWidget {
  const WeatherDetails({super.key, required this.data});

  final WeatherData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        final metricsColumns = constraints.maxWidth > 840
            ? 3
            : constraints.maxWidth > 520
            ? 2
            : 1;
        final chipSpacing = isWide ? 12.0 : 10.0;
        final headlineStyle =
            Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.2,
            ) ??
            const TextStyle(
              fontSize: 54,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            );

        final locationLine = data.country == null
            ? data.city
            : '${data.city}, ${data.country}';
        final observation = data.observationTime?.toLocal();
        final localization = MaterialLocalizations.of(context);
        final observationLabel = observation != null
            ? '${localization.formatMediumDate(observation)} • '
                  '${localization.formatTimeOfDay(TimeOfDay.fromDateTime(observation))}'
            : 'Updated moments ago';

        final gradient = _temperatureGradient(data.temperature);
        final icon = _iconForCode(data.weatherCode);

        final chips = [
          _InfoChip(label: data.description, icon: Icons.waves_outlined),
          _InfoChip(
            label: 'Feels like ${data.feelsLike.toStringAsFixed(1)}°C',
            icon: Icons.thermostat_auto,
          ),
          _InfoChip(
            label: '${data.humidity}% humidity',
            icon: Icons.water_drop_outlined,
          ),
        ];

        final metrics = [
          _MetricCardData(
            title: 'Feels like',
            value: '${data.feelsLike.toStringAsFixed(1)}°C',
            subtitle: 'Perceived temperature',
            icon: Icons.device_thermostat,
          ),
          _MetricCardData(
            title: 'Humidity',
            value: '${data.humidity}%',
            subtitle: 'Relative humidity',
            icon: Icons.water_drop,
          ),
          _MetricCardData(
            title: 'Wind speed',
            value: '${data.windSpeed.toStringAsFixed(1)} m/s',
            subtitle: '10 m above ground',
            icon: Icons.air,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(isWide ? 36 : 26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isWide ? 42 : 30),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient.last.withOpacity(0.35),
                    blurRadius: 42,
                    offset: const Offset(0, 28),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationLine,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              observationLabel,
                              style:
                                  Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70) ??
                                  const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Icon(
                            icon,
                            size: isWide ? 72 : 56,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${data.temperature.toStringAsFixed(1)}°C',
                            style: headlineStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isWide ? 28 : 20),
                  Wrap(
                    spacing: chipSpacing,
                    runSpacing: chipSpacing,
                    children: chips,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _MetricsGrid(columns: metricsColumns, metrics: metrics),
          ],
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.columns, required this.metrics});

  final int columns;
  final List<_MetricCardData> metrics;

  @override
  Widget build(BuildContext context) {
    final spacing = 18.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: columns == 1 ? constraints.maxWidth : cardWidth,
                  child: _MetricCard(data: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(data.icon, color: const Color(0xFF58D5FF)),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ) ??
                const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style:
                Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style:
                Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white54) ??
                const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _temperatureGradient(double temperature) {
  final base = _temperatureColor(temperature);
  final accent = Color.lerp(base, Colors.white, 0.25) ?? base;
  return [base.withOpacity(0.95), accent.withOpacity(0.9)];
}

Color _temperatureColor(double temperature) {
  if (temperature <= 0) {
    return const Color(0xFF4A90E2);
  }
  if (temperature < 15) {
    return const Color(0xFF50C9C3);
  }
  if (temperature < 25) {
    return const Color(0xFF78C850);
  }
  if (temperature < 32) {
    return const Color(0xFFF5A623);
  }
  return const Color(0xFFEF5350);
}

IconData _iconForCode(int code) {
  if ({0, 1}.contains(code)) {
    return Icons.wb_sunny;
  }
  if ({2}.contains(code)) {
    return Icons.cloud_queue;
  }
  if ({3, 45, 48}.contains(code)) {
    return Icons.cloud;
  }
  if ({51, 53, 55, 56, 57, 61, 63}.contains(code)) {
    return Icons.grain;
  }
  if ({65, 66, 67, 80, 81, 82}.contains(code)) {
    return Icons.beach_access;
  }
  if ({71, 73, 75, 77, 85, 86}.contains(code)) {
    return Icons.ac_unit;
  }
  if ({95, 96, 99}.contains(code)) {
    return Icons.flash_on;
  }
  return Icons.cloud_queue;
}
