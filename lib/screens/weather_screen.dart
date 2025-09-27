import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_suggestion.dart';
import '../providers/weather_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/weather_details.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<WeatherProvider>().searchQuery;
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    context.read<WeatherProvider>().search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: Consumer<WeatherProvider>(
        builder: (context, provider, _) => FloatingActionButton.extended(
          onPressed: provider.isLoading ? null : provider.refresh,
          icon: const Icon(Icons.my_location),
          label: const Text('Refresh'),
          backgroundColor: const Color(0xFF58D5FF),
          foregroundColor: const Color(0xFF0D1F25),
        ),
      ),
      body: Stack(
        children: [
          const _AuroraBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 720;
                final horizontal = isWide ? 48.0 : 20.0;
                final vertical = isWide ? 36.0 : 24.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    vertical,
                    horizontal,
                    0,
                  ),
                  child: Consumer<WeatherProvider>(
                    builder: (context, provider, _) {
                      final weather = provider.weather;

                      final slivers = <Widget>[
                        SliverToBoxAdapter(child: _Header(isWide: isWide)),
                        SliverToBoxAdapter(
                          child: SizedBox(height: isWide ? 28 : 20),
                        ),
                        SliverToBoxAdapter(
                          child: _SearchBar(
                            controller: _controller,
                            onSubmit: provider.isLoading ? null : _onSubmit,
                            isLoading: provider.isLoading,
                            provider: provider,
                            isWide: isWide,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: isWide ? 32 : 24),
                        ),
                      ];

                      if (provider.isLoading && weather == null) {
                        slivers.add(
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _LoadingState(),
                          ),
                        );
                      } else if (provider.error != null && weather == null) {
                        slivers.add(
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ErrorView(
                              onRetry: provider.refresh,
                              message: provider.error!,
                            ),
                          ),
                        );
                      } else if (weather == null) {
                        slivers.add(
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(isWide: isWide),
                          ),
                        );
                      } else {
                        slivers.addAll([
                          SliverToBoxAdapter(
                            child: WeatherDetails(data: weather),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          if (provider.error != null)
                            SliverToBoxAdapter(
                              child: _InlineErrorBanner(
                                message: provider.error!,
                                onRetry: provider.refresh,
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  vertical +
                                  MediaQuery.of(context).padding.bottom +
                                  80,
                            ),
                          ),
                        ]);
                      }

                      return RefreshIndicator(
                        onRefresh: provider.refresh,
                        color: Colors.white,
                        backgroundColor: Colors.black54,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: slivers,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmit,
    required this.isLoading,
    required this.provider,
    required this.isWide,
  });

  final TextEditingController controller;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final WeatherProvider provider;
  final bool isWide;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  Timer? _debounce;
  bool _isSelecting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_isSelecting) {
      return;
    }

    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      widget.provider.clearSuggestions();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 320), () {
      widget.provider.loadSuggestions(trimmed);
    });
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    _debounce?.cancel();
    _isSelecting = true;
    widget.controller.text = suggestion.displayName;
    _isSelecting = false;
    widget.provider.selectSuggestion(suggestion);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.provider.suggestions;
    final suggestionsError = widget.provider.suggestionsError;
    final showPanel =
        widget.provider.areSuggestionsLoading ||
        suggestions.isNotEmpty ||
        suggestionsError != null;

    final borderRadius = BorderRadius.circular(widget.isWide ? 28 : 22);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            color: Colors.white.withValues(alpha: 0.08),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isWide ? 26 : 18,
                  vertical: widget.isWide ? 20 : 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                        decoration: const InputDecoration(
                          hintText: 'Search by city, state, or country',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onChanged: _onChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          widget.provider.clearSuggestions();
                          widget.onSubmit?.call();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: widget.onSubmit == null
                          ? null
                          : () {
                              widget.provider.clearSuggestions();
                              widget.onSubmit!.call();
                            },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isWide ? 22 : 18,
                          vertical: 16,
                        ),
                        backgroundColor: const Color(0xFF58D5FF),
                        foregroundColor: const Color(0xFF06212A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Text('Explore'),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: showPanel
                    ? _SuggestionsPanel(
                        key: const ValueKey('suggestions'),
                        isLoading: widget.provider.areSuggestionsLoading,
                        suggestions: suggestions,
                        error: suggestionsError,
                        onSelect: _selectSuggestion,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final LocationSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (suggestion.admin1 != null && suggestion.admin1!.isNotEmpty)
        suggestion.admin1!,
      if (suggestion.country != null && suggestion.country!.isNotEmpty)
        suggestion.country!,
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitleParts.isNotEmpty)
                    Text(
                      subtitleParts.join(', '),
                      style: const TextStyle(color: Colors.white60),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    super.key,
    required this.isLoading,
    required this.suggestions,
    required this.error,
    required this.onSelect,
  });

  final bool isLoading;
  final List<LocationSuggestion> suggestions;
  final String? error;
  final ValueChanged<LocationSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              )
            : suggestions.isNotEmpty
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _SuggestionTile(
                    suggestion: suggestions[index],
                    onTap: () => onSelect(suggestions[index]),
                  ),
                ),
              )
            : Text(
                error ?? 'No matches found.',
                style: const TextStyle(color: Colors.white70),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Clima', style: headline),
              TextSpan(
                text: 'Scope',
                style: headline?.copyWith(color: const Color(0xFF58D5FF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Crafted forecasts, live insights, and city discoveries at your fingertips.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _HighlightChip(icon: Icons.speed, label: 'Real-time data'),
            _HighlightChip(icon: Icons.language, label: 'Global coverage'),
            _HighlightChip(icon: Icons.timeline, label: 'Smart insights'),
          ],
        ),
      ],
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF58D5FF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF051821), Color(0xFF0A3B52), Color(0xFF102B45)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowCircle(
              diameter: 320,
              colors: [
                const Color(0xFF58D5FF).withOpacity(0.45),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            top: 240,
            right: -100,
            child: _GlowCircle(
              diameter: 280,
              colors: [
                const Color(0xFF707CFF).withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _GlowCircle(
              diameter: 360,
              colors: [
                const Color(0xFF36C4D7).withOpacity(0.35),
                Colors.transparent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.colors});

  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: diameter,
      width: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6F61).withOpacity(0.8),
              const Color(0xFFFFA36C).withOpacity(0.6),
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 64,
        width: 64,
        child: CircularProgressIndicator(
          key: Key('weather_loader'),
          color: Colors.white,
          strokeWidth: 4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final iconSize = isWide ? 96.0 : 80.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(
                Icons.public,
                size: iconSize,
                color: const Color(0xFF58D5FF),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Start exploring the world',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Type any destination to uncover live temperatures, humidity, winds, and more.',
              style: TextStyle(color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
