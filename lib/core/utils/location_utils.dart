import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for location-related operations
class LocationUtils {
  LocationUtils._();

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position with high accuracy
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check permission first
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled. Prompting user to enable...');
        // Open location settings
        await openLocationSettings();

        // Wait a bit for the user to potentially turn it on
        await Future.delayed(const Duration(seconds: 4));

        // Check again
        final serviceEnabledAfter = await isLocationServiceEnabled();
        if (!serviceEnabledAfter) {
          debugPrint('Location services still disabled after prompt.');
          return null;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert meters to kilometers
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Get bounding box coordinates for a given radius around a point
  static Map<String, double> getBoundingBox({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    const double earthRadiusKm = 6371.0;

    final latRad = latitude * (math.pi / 180);

    final deltaLat = radiusKm / earthRadiusKm;
    final deltaLon = radiusKm / (earthRadiusKm * math.cos(latRad));

    return {
      'minLat': latitude - (deltaLat * 180 / math.pi),
      'maxLat': latitude + (deltaLat * 180 / math.pi),
      'minLon': longitude - (deltaLon * 180 / math.pi),
      'maxLon': longitude + (deltaLon * 180 / math.pi),
    };
  }

  /// Stream position updates
  static Stream<Position> getPositionStream({
    int distanceFilter = 100, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  static Future<bool> openAppSettings() async {
    return await Permission.notification.status.isGranted;
  }
}
