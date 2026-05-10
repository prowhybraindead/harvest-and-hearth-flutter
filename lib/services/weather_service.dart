import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.temperatureC,
    required this.weatherCode,
    required this.description,
    required this.source,
  });

  final String city;
  final double temperatureC;
  final int weatherCode;
  final String description;
  final String source;
}

class WeatherService {
  static const _ipLookupUrl = 'https://ipapi.co/json/';

  static Future<WeatherSnapshot> fetchCurrentWeather({
    required bool isVietnamese,
  }) async {
    final location = await _resolveLocation();
    final weather = await _fetchOpenMeteo(
      latitude: location.latitude,
      longitude: location.longitude,
      isVietnamese: isVietnamese,
    );
    return WeatherSnapshot(
      city: location.city,
      temperatureC: weather.temperatureC,
      weatherCode: weather.weatherCode,
      description: weather.description,
      source: location.source,
    );
  }

  static Future<_ResolvedLocation> _resolveLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _resolveByIp();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _resolveByIp();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      var city = 'Unknown city';
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        final place = placemarks.isNotEmpty ? placemarks.first : null;
        city = place?.locality?.trim().isNotEmpty == true
            ? place!.locality!.trim()
            : (place?.administrativeArea?.trim().isNotEmpty == true
                ? place!.administrativeArea!.trim()
                : city);
      } catch (_) {}
      return _ResolvedLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        city: city,
        source: 'gps',
      );
    } catch (_) {
      return _resolveByIp();
    }
  }

  static Future<_ResolvedLocation> _resolveByIp() async {
    final resp = await http.get(Uri.parse(_ipLookupUrl));
    if (resp.statusCode != 200) {
      throw Exception('Failed to resolve location');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return _ResolvedLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      city: (json['city'] as String?)?.trim().isNotEmpty == true
          ? (json['city'] as String).trim()
          : 'Unknown city',
      source: 'ip',
    );
  }

  static Future<_WeatherResponse> _fetchOpenMeteo({
    required double latitude,
    required double longitude,
    required bool isVietnamese,
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code&timezone=auto',
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch weather');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final current = (json['current'] as Map<String, dynamic>?) ?? {};
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0;
    return _WeatherResponse(
      temperatureC: temp,
      weatherCode: weatherCode,
      description: _weatherText(weatherCode, isVietnamese),
    );
  }

  static String _weatherText(int code, bool isVn) {
    switch (code) {
      case 0:
        return isVn ? 'Trời quang' : 'Clear sky';
      case 1:
      case 2:
      case 3:
        return isVn ? 'Có mây' : 'Partly cloudy';
      case 45:
      case 48:
        return isVn ? 'Sương mù' : 'Fog';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return isVn ? 'Mưa phùn' : 'Drizzle';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return isVn ? 'Mưa' : 'Rain';
      case 71:
      case 73:
      case 75:
      case 77:
        return isVn ? 'Tuyết' : 'Snow';
      case 80:
      case 81:
      case 82:
        return isVn ? 'Mưa rào' : 'Rain showers';
      case 95:
      case 96:
      case 99:
        return isVn ? 'Giông bão' : 'Thunderstorm';
      default:
        return isVn ? 'Thời tiết hiện tại' : 'Current weather';
    }
  }
}

class _ResolvedLocation {
  const _ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final String city;
  final String source;
}

class _WeatherResponse {
  const _WeatherResponse({
    required this.temperatureC,
    required this.weatherCode,
    required this.description,
  });

  final double temperatureC;
  final int weatherCode;
  final String description;
}
