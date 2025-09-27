import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/location_suggestion.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({WeatherService? service})
    : _service = service ?? WeatherService() {
    _searchQuery = defaultCity;
    Future.microtask(() => search(defaultCity));
  }

  final WeatherService _service;

  WeatherData? _weather;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = defaultCity;
  List<LocationSuggestion> _suggestions = const <LocationSuggestion>[];
  bool _areSuggestionsLoading = false;
  String? _suggestionsError;
  LocationSuggestion? _selectedLocation;
  int _suggestionRequestId = 0;
  String _lastSuggestionQuery = '';

  WeatherData? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<LocationSuggestion> get suggestions => List.unmodifiable(_suggestions);
  bool get areSuggestionsLoading => _areSuggestionsLoading;
  String? get suggestionsError => _suggestionsError;

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _error = 'Please enter a city name to search.';
      _weather = null;
      _notify();
      return;
    }

    _searchQuery = trimmed;
    _selectedLocation = null;
    _suggestions = const <LocationSuggestion>[];
    _suggestionsError = null;
    _isLoading = true;
    _error = null;
    _notify();

    try {
      final result = await _service.fetchWeather(trimmed);
      _weather = result;
      _error = null;
    } on WeatherException catch (error) {
      _weather = null;
      _error = error.message;
    } catch (error) {
      _weather = null;
      _error = 'Unexpected error: $error';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> refresh() {
    final suggestion = _selectedLocation;
    if (suggestion != null) {
      return selectSuggestion(suggestion);
    }
    return search(_searchQuery);
  }

  Future<void> loadSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _lastSuggestionQuery = '';
      _areSuggestionsLoading = false;
      _suggestions = const <LocationSuggestion>[];
      _suggestionsError = null;
      _notify();
      return;
    }

    if (trimmed == _lastSuggestionQuery && _suggestions.isNotEmpty) {
      return;
    }

    final requestId = ++_suggestionRequestId;

    _areSuggestionsLoading = true;
    _suggestionsError = null;
    _notify();

    try {
      final locations = await _service.searchLocations(trimmed);
      if (requestId != _suggestionRequestId) {
        return;
      }
      _lastSuggestionQuery = trimmed;
      _suggestions = locations;
      if (locations.isEmpty) {
        _suggestionsError = 'No matches found for "$trimmed".';
      }
    } on WeatherException catch (error) {
      if (requestId != _suggestionRequestId) {
        return;
      }
      _suggestions = const <LocationSuggestion>[];
      _suggestionsError = error.message;
    } catch (error) {
      if (requestId != _suggestionRequestId) {
        return;
      }
      _suggestions = const <LocationSuggestion>[];
      _suggestionsError = 'Unable to load suggestions: $error';
    } finally {
      if (requestId == _suggestionRequestId) {
        _areSuggestionsLoading = false;
        _notify();
      }
    }
  }

  void clearSuggestions() {
    if (_suggestions.isEmpty && _suggestionsError == null) {
      return;
    }
    _suggestionRequestId++;
    _lastSuggestionQuery = '';
    _areSuggestionsLoading = false;
    _suggestions = const <LocationSuggestion>[];
    _suggestionsError = null;
    _notify();
  }

  Future<void> selectSuggestion(LocationSuggestion suggestion) async {
    _suggestionRequestId++;
    _areSuggestionsLoading = false;
    _lastSuggestionQuery = '';
    _selectedLocation = suggestion;
    _searchQuery = suggestion.displayName;
    _suggestions = const <LocationSuggestion>[];
    _suggestionsError = null;
    _notify();

    _isLoading = true;
    _error = null;
    _notify();

    try {
      final result = await _service.fetchWeatherForSuggestion(suggestion);
      _weather = result;
      _error = null;
    } on WeatherException catch (error) {
      _weather = null;
      _error = error.message;
    } catch (error) {
      _weather = null;
      _error = 'Unexpected error: $error';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void _notify() {
    if (hasListeners) {
      notifyListeners();
    }
  }
}
