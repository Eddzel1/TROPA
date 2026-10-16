import 'dart:math';

/// A `locations` row as used by the LGU/barangay pickers, with the barangay center.
typedef LocationOption = ({String id, String lgu, String barangay, double? latitude, double? longitude});

typedef LatLngPoint = ({double latitude, double longitude});

final _random = Random();

/// Center of the given LGU + barangay from [locations], or null if it has no coordinates.
LatLngPoint? barangayCenter(List<LocationOption> locations, String lgu, String barangay) {
  final l = lgu.trim().toUpperCase();
  final b = barangay.trim().toUpperCase();
  for (final loc in locations) {
    if (loc.lgu == l && loc.barangay == b && loc.latitude != null && loc.longitude != null) {
      return (latitude: loc.latitude!, longitude: loc.longitude!);
    }
  }
  return null;
}

/// A random point uniformly within [radiusMeters] of [center], so saved member
/// locations are approximate rather than an exact address.
LatLngPoint jitterAround(LatLngPoint center, {double radiusMeters = 500}) {
  const metersPerDegree = 111320.0;
  final r = radiusMeters * sqrt(_random.nextDouble());
  final t = 2 * pi * _random.nextDouble();
  return (
    latitude: center.latitude + r * cos(t) / metersPerDegree,
    longitude: center.longitude + r * sin(t) / (metersPerDegree * cos(center.latitude * pi / 180)),
  );
}
