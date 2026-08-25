import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  /// Calculate Haversine distance in Kilometers between two coordinates
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }

  /// Calculate realistic Sri Lankan traffic ETA in minutes (avg speed 25km/h + 3 min buffer)
  static int calculateEstimatedMinutes(double distanceKm) {
    if (distanceKm <= 0.2) return 2;
    final minutes = ((distanceKm / 25.0) * 60).round() + 3;
    return max(minutes, 3);
  }

  /// Launch external turn-by-turn navigation (Google Maps, Apple Maps, Waze)
  static Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    // 1. Try Google Navigation intent (Native on Android)
    final googleNavUri = Uri.parse(
      'google.navigation:q=$latitude,$longitude&mode=d',
    );

    // 2. Standard Google Maps universal web / app deep link
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleNavUri)) {
        return await launchUrl(googleNavUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching navigation: $e');
    }
    return false;
  }

  /// Launch phone call intent
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
    return false;
  }
}
