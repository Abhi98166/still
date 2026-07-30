import 'package:intl/intl.dart';

abstract final class StillDates {
  static String longDay(DateTime d) => DateFormat('EEEE d MMMM').format(d);

  static String shortDay(DateTime d) => DateFormat('EEE d MMMM').format(d);

  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  static String dayMonthAbbrev(DateTime d) => DateFormat('d MMM').format(d);

  static String monthAbbrev(DateTime d) => DateFormat('MMM').format(d);

  static String fullDate(DateTime d) => DateFormat('d MMMM yyyy').format(d);

  static String weekday(DateTime d) => DateFormat('EEEE').format(d);

  static String timeOfDay(DateTime d) => DateFormat('HH:mm').format(d);

  static const List<String> weekdayInitials = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  static int leadingBlanks(DateTime firstOfMonth) => firstOfMonth.weekday - 1;

  static int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

  static String greeting(DateTime now) =>
      now.hour < 12 ? 'Good morning.' : 'Good evening.';
}
