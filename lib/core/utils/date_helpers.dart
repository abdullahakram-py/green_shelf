import 'package:intl/intl.dart';

class DateHelpers {
  DateHelpers._();

  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _readableFormat = DateFormat('d MMM yyyy');
  static final DateFormat _shortFormat = DateFormat('d MMM');
  static final DateFormat _headerDateFormat = DateFormat('EEEE, d MMMM');

  /// Convert DateTime to date-only ISO string (yyyy-MM-dd)
  static String toIsoDate(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Parse date-only ISO string to local DateTime (midnight)
  static DateTime parseIsoDate(String isoString) {
    try {
      final parts = isoString.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime.parse(isoString);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Format DateTime to readable string e.g. "2 Oct 2026"
  static String formatReadable(DateTime date) {
    return _readableFormat.format(date);
  }

  /// Format DateTime to short readable string e.g. "2 Oct"
  static String formatShort(DateTime date) {
    return _shortFormat.format(date);
  }

  /// Format DateTime for header e.g. "Thursday, 1 October"
  static String formatHeaderDate(DateTime date) {
    return _headerDateFormat.format(date);
  }

  /// Strip time component and return pure date
  static DateTime stripTime(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Greeting based on current hour
  static String getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
