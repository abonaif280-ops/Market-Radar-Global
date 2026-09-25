import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../location/coordinates.dart';

/// يسلّم الإحداثية لتطبيق الخرائط المثبت. التطبيق نفسه لا يتصل بالإنترنت.
abstract interface class MapLauncher {
  /// يعيد false إذا لم يوجد تطبيق خرائط يفتح الرابط.
  Future<bool> open(Coordinates coordinates, {String? label});
}

class SystemMapLauncher implements MapLauncher {
  const SystemMapLauncher();

  @override
  Future<bool> open(Coordinates coordinates, {String? label}) async {
    final uri = mapUri(coordinates, label: label, ios: Platform.isIOS);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  /// Android: رابط `geo:` يفتح أي تطبيق خرائط. iOS: رابط `maps:` لتطبيق Apple Maps.
  static Uri mapUri(Coordinates c, {String? label, required bool ios}) {
    final latLng =
        '${c.latitude.toStringAsFixed(6)},${c.longitude.toStringAsFixed(6)}';
    if (ios) {
      return Uri(
        scheme: 'maps',
        queryParameters: {'ll': latLng, 'q': label ?? latLng},
      );
    }
    final query = label == null ? latLng : '$latLng($label)';
    return Uri.parse('geo:$latLng?q=${Uri.encodeComponent(query)}');
  }
}
