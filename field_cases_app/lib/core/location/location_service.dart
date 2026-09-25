import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import 'coordinates.dart';

/// نتيجة محاولة التقاط الموقع.
sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  const LocationSuccess(this.coordinates, {this.accuracyMeters});

  final Coordinates coordinates;
  final double? accuracyMeters;
}

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permanentlyDenied,
  timeout,
  unknown,
}

class LocationFailure extends LocationResult {
  const LocationFailure(this.reason, [this.details]);

  final LocationFailureReason reason;
  final String? details;

  String get message => switch (reason) {
    LocationFailureReason.serviceDisabled =>
      'خدمة الموقع متوقفة في الجهاز. فعّلها ثم حاول مجددًا.',
    LocationFailureReason.permissionDenied =>
      'لم يُسمح للتطبيق باستخدام الموقع.',
    LocationFailureReason.permanentlyDenied =>
      'إذن الموقع مرفوض دائمًا. يمكن تفعيله من إعدادات الجهاز.',
    LocationFailureReason.timeout => 'تعذر تحديد الموقع في الوقت المحدد. جرّب في مكان مكشوف أو أدخل الإحداثية يدويًا.',
    LocationFailureReason.unknown => 'تعذر تحديد الموقع.',
  };
}

/// واجهة مجردة لالتقاط الموقع حتى يمكن استبدالها في الاختبارات.
abstract interface class LocationService {
  Future<LocationResult> currentLocation();

  Future<void> openSystemSettings();
}

/// التقاط الموقع من GPS الجهاز مباشرة، دون أي اتصال بالشبكة.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({
    this.timeLimit = const Duration(seconds: 30),
  });

  final Duration timeLimit;

  @override
  Future<LocationResult> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationFailure(LocationFailureReason.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationFailure(LocationFailureReason.permanentlyDenied);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationFailure(LocationFailureReason.permissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.best,
                timeLimit: timeLimit,
                // GPS الجهاز مباشرة بدل خدمات Google Play.
                forceLocationManager: true,
              )
            : AppleSettings(
                accuracy: LocationAccuracy.best,
                timeLimit: timeLimit,
              ),
      );
      return LocationSuccess(
        Coordinates(position.latitude, position.longitude),
        accuracyMeters: position.accuracy,
      );
    } on TimeoutException {
      return const LocationFailure(LocationFailureReason.timeout);
    } on LocationServiceDisabledException {
      return const LocationFailure(LocationFailureReason.serviceDisabled);
    } on PermissionDeniedException catch (e) {
      return LocationFailure(LocationFailureReason.permissionDenied, e.message);
    } on Exception catch (e) {
      return LocationFailure(LocationFailureReason.unknown, '$e');
    }
  }

  @override
  Future<void> openSystemSettings() => Geolocator.openAppSettings();
}
