import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class TimezoneHelper {
  static String getCityTime(String timezone) {
    final location = tz.getLocation(timezone);
    final now = tz.TZDateTime.now(location);

    return DateFormat('hh:mm a').format(now);
  }
}