import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();
  
  final locations = ['Asia/Calcutta', 'Asia/Kolkata', 'UTC'];
  
  for (var loc in locations) {
    try {
      final l = tz.getLocation(loc);
      print('Location $loc found: ${l.name}');
    } catch (e) {
      print('Location $loc NOT found: $e');
    }
  }
  
  // Test fallback logic
  String identifier = 'Asia/Calcutta';
  tz.Location location;
  try {
    location = tz.getLocation(identifier);
  } catch (_) {
    try {
      print('Falling back from $identifier');
      location = tz.getLocation('Asia/Kolkata');
    } catch (_) {
      location = tz.UTC;
    }
  }
  print('Resolved location: ${location.name}');
}
