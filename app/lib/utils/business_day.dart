import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;

/// Rolls [date] forward to the next business day (not Sat/Sun, not a
/// Japanese public holiday) — for a monthly/yearly anniversary that
/// represents a due date rather than the event itself (e.g. "payment day:
/// the 25th, but move to the next business day if that's a weekend or
/// holiday"). Returns [date] unchanged if it's already a business day.
DateTime adjustToNextBusinessDay(DateTime date) {
  var d = date;
  while (d.weekday == DateTime.saturday ||
      d.weekday == DateTime.sunday ||
      holiday_jp.isHoliday(d)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}
