import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/anniversary.dart';
import '../../models/schedule.dart';
import '../../models/schedule_category.dart';
import '../../models/shared_group.dart';
import '../../services/weather_service.dart';
import '../schedule/schedule_detail_screen.dart';
import '../schedule/schedule_form_screen.dart';

enum _ViewMode { calendar, list }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  _ViewMode _viewMode = _ViewMode.calendar;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // Calendars (null = 個人の予定, otherwise a groupId) that are hidden via
  // the filter. Empty means everything is shown.
  final Set<String?> _hiddenCalendarIds = {};

  // Populated from a StreamBuilder in build() before the calendar grid is
  // built, since calendarBuilders callbacks are synchronous.
  List<Anniversary> _anniversaries = [];
  List<({String name, int month, int day})> _friendBirthdays = [];
  String? _friendBirthdaysMemberKey;
  List<WeatherDay> _forecast = [];
  String? _tenkiKeyword;
  // Populated at the top of _buildCalendarView so _buildDayCell (called by
  // table_calendar's synchronous builders) can look up each day's events.
  Map<DateTime, List<Schedule>> _schedulesByDay = {};

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final lat = userDoc.data()?['weather_lat'] as num?;
    final lon = userDoc.data()?['weather_lon'] as num?;
    _tenkiKeyword = userDoc.data()?['weather_tenki_keyword'] as String?;
    if (lat == null || lon == null) return;

    try {
      final forecast =
          await WeatherService.instance.fetchForecast(lat: lat.toDouble(), lon: lon.toDouble());
      if (mounted) setState(() => _forecast = forecast);
    } catch (_) {
      // No connection or the free API is temporarily unavailable — the
      // calendar still works fine without weather icons.
    }
  }

  WeatherDay? _weatherForDay(DateTime day) {
    for (final weatherDay in _forecast) {
      if (_isSameDay(weatherDay.date, day)) return weatherDay;
    }
    return null;
  }

  /// Opens tenki.jp for more detail than the app's own simple high/low/rain
  /// summary shows — deep-linked to the user's own region when known
  /// (tenki.jp resolves wards our free geocoder has no data for at all,
  /// like 大正区/浪速区), otherwise just the general weekly forecast.
  Future<void> _openDetailedForecast() async {
    final keyword = _tenkiKeyword;
    final uri = (keyword == null || keyword.isEmpty)
        ? Uri.parse('https://tenki.jp/week/')
        : Uri.https('tenki.jp', '/search/', {'keyword': keyword});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Well-known annual observances that are not official Japanese public
  // holidays (so they don't get colored red), keyed by (month, day).
  Map<(int, int), String> _specialDays(AppLocalizations l10n) => {
        (12, 24): l10n.calendarChristmasEve,
        (12, 25): l10n.calendarChristmas,
        (12, 31): l10n.calendarNewYearsEve,
      };

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// The date of the [n]th [weekday] in [month]/[year] (e.g. the 2nd Sunday
  /// of May). Computed per-year since it shifts, unlike a fixed month/day.
  DateTime _nthWeekdayOfMonth(int year, int month, int weekday, int n) {
    final firstOfMonth = DateTime(year, month, 1);
    final offsetToFirstWeekday = (weekday - firstOfMonth.weekday + 7) % 7;
    return firstOfMonth.add(Duration(days: offsetToFirstWeekday + 7 * (n - 1)));
  }

  // holiday_jp ships a static table only through 2050, computed once at
  // package-build time — Japan's government only officially confirms
  // 春分の日/秋分の日 about a year ahead, so the package's guess for
  // further-out years can drift a day off the real astronomical date.
  // These use the standard approximation (accurate 1980–2099) instead, so
  // the calendar doesn't show the wrong day for future years.
  int _vernalEquinoxDay(int year) =>
      (20.8431 + 0.242194 * (year - 1980)).floor() - ((year - 1980) / 4).floor();

  int _autumnalEquinoxDay(int year) =>
      (23.2488 + 0.242194 * (year - 1980)).floor() - ((year - 1980) / 4).floor();

  /// Resolves the holiday for [day], preferring our own computed equinox
  /// date over holiday_jp's for 春分の日/秋分の日 specifically.
  holiday_jp.Holiday? _holidayFor(DateTime day) {
    final isComputedVernalEquinox = day.month == 3 && day.day == _vernalEquinoxDay(day.year);
    final isComputedAutumnalEquinox = day.month == 9 && day.day == _autumnalEquinoxDay(day.year);
    if (isComputedVernalEquinox || isComputedAutumnalEquinox) {
      final l10n = AppLocalizations.of(context)!;
      return holiday_jp.Holiday(
        date: '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        week: '',
        weekEn: '',
        name: isComputedVernalEquinox ? l10n.calendarVernalEquinox : l10n.calendarAutumnalEquinox,
        nameEn: isComputedVernalEquinox ? 'Vernal Equinox Day' : 'Autumnal Equinox Day',
      );
    }

    final packageHoliday = holiday_jp.getHoliday(day);
    // Suppress the package's own (possibly wrong, for future years) guess
    // at the primary equinox day so it doesn't show alongside/instead of
    // our computed one on the wrong date.
    if (packageHoliday != null &&
        (packageHoliday.name == '春分の日' || packageHoliday.name == '秋分の日')) {
      return null;
    }
    return packageHoliday;
  }

  bool _isHolidayOrSunday(DateTime day) {
    return day.weekday == DateTime.sunday || _holidayFor(day) != null;
  }

  String? _specialDayName(DateTime day) {
    final l10n = AppLocalizations.of(context)!;
    final fixed = _specialDays(l10n)[(day.month, day.day)];
    if (fixed != null) return fixed;

    // 母の日 (5月第2日曜) and 父の日 (6月第3日曜) move every year, so they're
    // computed relative to `day.year` rather than stored as a fixed date.
    if (_isSameDay(day, _nthWeekdayOfMonth(day.year, 5, DateTime.sunday, 2))) {
      return l10n.calendarMothersDay;
    }
    if (_isSameDay(day, _nthWeekdayOfMonth(day.year, 6, DateTime.sunday, 3))) {
      return l10n.calendarFathersDay;
    }
    return null;
  }

  /// Names of the signed-in user's own anniversaries, plus friends'/family's
  /// birthdays (shared via groups), that fall on [day] this year.
  List<String> _anniversaryNamesForDay(DateTime day) {
    final l10n = AppLocalizations.of(context)!;
    final names = <String>[];
    for (final anniversary in _anniversaries) {
      if (anniversary.month == day.month && anniversary.day == day.day) {
        names.add(anniversary.title);
      }
    }
    for (final birthday in _friendBirthdays) {
      if (birthday.month == day.month && birthday.day == day.day) {
        names.add(l10n.calendarBirthdaySuffix(birthday.name));
      }
    }
    return names;
  }

  /// Loads birthMonth/birthDay from the public profiles of everyone in the
  /// user's groups, so their birthdays can show on this user's calendar too.
  /// Re-fetches only when the set of group members actually changes.
  Future<void> _loadFriendBirthdays(String uid, List<SharedGroup> groups) async {
    final memberIds = <String>{};
    for (final group in groups) {
      memberIds.addAll(group.memberIds);
    }
    memberIds.remove(uid);

    final key = (memberIds.toList()..sort()).join(',');
    if (key == _friendBirthdaysMemberKey) return;
    _friendBirthdaysMemberKey = key;

    if (memberIds.isEmpty) {
      if (mounted) setState(() => _friendBirthdays = []);
      return;
    }

    // Firestore documentId-whereIn supports at most 30 values; larger groups
    // of groups are truncated for now rather than paginating.
    final ids = memberIds.take(30).toList();
    final snapshot = await FirebaseFirestore.instance
        .collection('publicProfiles')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    final birthdays = <({String name, int month, int day})>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final month = data['birthMonth'] as int?;
      final day = data['birthDay'] as int?;
      final name = data['displayName'] as String? ?? '';
      if (month != null && day != null && name.isNotEmpty) {
        birthdays.add((name: name, month: month, day: day));
      }
    }

    if (mounted) setState(() => _friendBirthdays = birthdays);
  }

  /// Renders a day cell as a small agenda: day number + weather at top,
  /// then the day's schedule titles (colored to match each schedule), so
  /// events are visible at a glance instead of just a dot marker.
  Widget _buildDayCell(
    BuildContext context, {
    required DateTime day,
    bool isToday = false,
    bool isSelected = false,
  }) {
    Color numberColor;
    if (isSelected) {
      numberColor = Colors.white;
    } else if (_isHolidayOrSunday(day)) {
      numberColor = const Color(0xFFEF4444);
    } else if (day.weekday == DateTime.saturday) {
      numberColor = const Color(0xFF2563EB);
    } else {
      numberColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    }

    final holidayName = _holidayFor(day)?.name;
    final anniversaryNames = _anniversaryNamesForDay(day);
    final labelName = holidayName ??
        (anniversaryNames.isNotEmpty ? anniversaryNames.first : null) ??
        _specialDayName(day);
    final labelColor = holidayName != null
        ? const Color(0xFFEF4444)
        : (anniversaryNames.isNotEmpty ? const Color(0xFFEC4899) : const Color(0xFFB45309));

    final weather = _weatherForDay(day);
    final events = _schedulesByDay[DateTime(day.year, day.month, day.day)] ?? const <Schedule>[];
    const maxVisibleEvents = 1;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  border: isToday && !isSelected
                      ? Border.all(color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                child: Text('${day.day}', style: TextStyle(fontSize: 12, color: numberColor)),
              ),
              const Spacer(),
              if (weather != null) Text(weather.emoji, style: const TextStyle(fontSize: 9)),
            ],
          ),
          if (labelName != null)
            Text(
              labelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 7, color: labelColor),
            ),
          for (final schedule in events.take(maxVisibleEvents))
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: schedule.color,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                schedule.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8, color: Colors.white),
              ),
            ),
          if (events.length > maxVisibleEvents)
            Text(
              '+${events.length - maxVisibleEvents}',
              style: TextStyle(fontSize: 7, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Future<void> _openMonthPicker(DateTime currentFocusedDay) async {
    var year = currentFocusedDay.year;
    var month = currentFocusedDay.month;
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.calendarMonthPickerTitle),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: year,
                items: [
                  for (var y = 2020; y <= 2035; y++)
                    DropdownMenuItem(value: y, child: Text(l10n.calendarMonthPickerYear(y))),
                ],
                onChanged: (value) => setDialogState(() => year = value!),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: month,
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(value: m, child: Text(l10n.calendarMonthPickerMonth(m))),
                ],
                onChanged: (value) => setDialogState(() => month = value!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, DateTime(year, month, 1)),
              child: Text(l10n.calendarMonthPickerGo),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _focusedDay = result);
    }
  }

  Future<void> _openCalendarFilter(List<SharedGroup> groups) async {
    final hidden = Set<String?>.from(_hiddenCalendarIds);
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.calendarFilterTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  secondary: const Icon(Icons.label_outline, size: 20),
                  title: Text(personalCategoryDefaultLabel(l10n)),
                  value: !hidden.contains(null),
                  onChanged: (checked) {
                    setDialogState(() {
                      checked == true ? hidden.remove(null) : hidden.add(null);
                    });
                  },
                ),
                ...personalCategories(l10n).entries.map((entry) {
                  return CheckboxListTile(
                    secondary: const Icon(Icons.label_outline, size: 20),
                    title: Text(entry.value),
                    value: !hidden.contains(entry.key),
                    onChanged: (checked) {
                      setDialogState(() {
                        checked == true ? hidden.remove(entry.key) : hidden.add(entry.key);
                      });
                    },
                  );
                }),
                ...groups.map((group) {
                  return CheckboxListTile(
                    secondary: const Icon(Icons.groups_outlined, size: 20),
                    title: Text('${group.name}${l10n.scheduleFormGroupSuffix}'),
                    value: !hidden.contains(group.id),
                    onChanged: (checked) {
                      setDialogState(() {
                        checked == true ? hidden.remove(group.id) : hidden.add(group.id);
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _hiddenCalendarIds
                    ..clear()
                    ..addAll(hidden);
                });
                Navigator.pop(context);
              },
              child: Text(l10n.calendarFilterClose),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final schedulesQuery = FirebaseFirestore.instance
        .collection('schedules')
        .where('participantIds', arrayContains: uid)
        .orderBy('startTime');
    final groupsQuery =
        FirebaseFirestore.instance.collection('sharedGroups').where('memberIds', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.calendarTitle),
            Text(
              l10n.calendarTagline,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: groupsQuery.snapshots(),
            builder: (context, groupSnapshot) {
              final groups = groupSnapshot.hasData
                  ? groupSnapshot.data!.docs.map((doc) => SharedGroup.fromFirestore(doc)).toList()
                  : <SharedGroup>[];
              return IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: l10n.calendarFilterTooltip,
                onPressed: () => _openCalendarFilter(groups),
              );
            },
          ),
          IconButton(
            icon: Icon(_viewMode == _ViewMode.calendar
                ? Icons.view_list_outlined
                : Icons.calendar_month_outlined),
            tooltip: _viewMode == _ViewMode.calendar ? l10n.calendarViewList : l10n.calendarViewCalendar,
            onPressed: () {
              setState(() {
                _viewMode =
                    _viewMode == _ViewMode.calendar ? _ViewMode.list : _ViewMode.calendar;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: groupsQuery.snapshots(),
        builder: (context, groupSnapshot) {
          final groups = groupSnapshot.hasData
              ? groupSnapshot.data!.docs.map((doc) => SharedGroup.fromFirestore(doc)).toList()
              : const <SharedGroup>[];
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadFriendBirthdays(uid, groups));

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('anniversaries')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, anniversarySnapshot) {
          _anniversaries = anniversarySnapshot.hasData
              ? anniversarySnapshot.data!.docs
                  .map((doc) => Anniversary.fromFirestore(doc))
                  .toList()
              : const <Anniversary>[];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: schedulesQuery.snapshots(),
            builder: (context, snapshot) {
              // Even if the schedules failed to load, still show the
              // calendar grid itself (empty) instead of blanking the screen.
              final schedules = snapshot.hasData
                  ? snapshot.data!.docs
                      .map((doc) => Schedule.fromFirestore(doc))
                      .where((s) => !_hiddenCalendarIds.contains(s.groupId))
                      .toList()
                  : <Schedule>[];

              final content = _viewMode == _ViewMode.calendar
                  ? _buildCalendarView(schedules)
                  : _buildListView(schedules);

              if (snapshot.hasError) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.red.shade50,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        l10n.calendarLoadError,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(child: content),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return content;
            },
          );
        },
      );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScheduleFormScreen(initialDate: _selectedDay),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarView(List<Schedule> schedules) {
    final l10n = AppLocalizations.of(context)!;
    final schedulesByDay = <DateTime, List<Schedule>>{};
    for (final schedule in schedules) {
      final day = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      schedulesByDay.putIfAbsent(day, () => []).add(schedule);
    }
    _schedulesByDay = schedulesByDay;

    final selectedDaySchedules =
        schedules.where((s) => _isSameDay(s.startTime, _selectedDay)).toList();

    // Wrapped in a scroll view so a 6-row month (or a small screen) never
    // overflows into the bottom navigation bar — it scrolls instead.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<CalendarFormat>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: [
                ButtonSegment(value: CalendarFormat.month, label: Text(l10n.calendarFormatMonth)),
                ButtonSegment(value: CalendarFormat.week, label: Text(l10n.calendarFormatWeek)),
              ],
              selected: {_calendarFormat},
              onSelectionChanged: (selection) =>
                  setState(() => _calendarFormat = selection.first),
            ),
          ),
        ),
        TableCalendar<Schedule>(
          locale: Localizations.localeOf(context).toString(),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
          eventLoader: (day) =>
              schedulesByDay[DateTime(day.year, day.month, day.day)] ?? [],
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
          startingDayOfWeek: StartingDayOfWeek.monday,
          onHeaderTapped: _openMonthPicker,
          headerStyle: const HeaderStyle(
            titleCentered: true,
            // The SegmentedButton above already switches month/week.
            formatButtonVisible: false,
          ),
          availableCalendarFormats: {
            CalendarFormat.month: l10n.calendarFormatMonth,
            CalendarFormat.week: l10n.calendarFormatWeek,
          },
          // Sunday and national holidays in red, Saturday in blue — the
          // conventional Japanese calendar color scheme.
          weekendDays: const [DateTime.saturday],
          holidayPredicate: _isHolidayOrSunday,
          calendarStyle: const CalendarStyle(
            weekendTextStyle: TextStyle(color: Color(0xFF2563EB)),
            holidayTextStyle: TextStyle(color: Color(0xFFEF4444)),
            outsideTextStyle: TextStyle(color: Colors.grey),
          ),
          // table_calendar's default daysOfWeekHeight (16px) is too tight for
          // these labels and makes them visually overlap; give them more room.
          daysOfWeekHeight: 22,
          // Day cells now show 1 schedule title directly, so they need a
          // bit more room than table_calendar's 52px default — but not so
          // much that month view (6 rows) overflows into the bottom nav bar.
          rowHeight: 58,
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekendStyle: TextStyle(color: Color(0xFF2563EB)),
          ),
          calendarBuilders: CalendarBuilders<Schedule>(
            dowBuilder: (context, day) {
              // Sunday's day-of-week header should read in red like holidays,
              // not the Saturday blue that daysOfWeekStyle.weekendStyle gives it.
              if (day.weekday != DateTime.sunday) return null;
              final label = DateFormat.E(Localizations.localeOf(context).toString()).format(day);
              return Center(
                child: Text(label, style: const TextStyle(color: Color(0xFFEF4444))),
              );
            },
            // today/selected take priority over holidayBuilder inside
            // table_calendar, so the holiday name would otherwise disappear
            // whenever a holiday is today or the selected day.
            holidayBuilder: (context, day, focusedDay) => _buildDayCell(context, day: day),
            todayBuilder: (context, day, focusedDay) =>
                _buildDayCell(context, day: day, isToday: true),
            selectedBuilder: (context, day, focusedDay) =>
                _buildDayCell(context, day: day, isSelected: true),
            // Also used for plain weekdays/Saturdays, so non-holiday special
            // days (母の日 etc.) still show their label.
            defaultBuilder: (context, day, focusedDay) => _buildDayCell(context, day: day),
            outsideBuilder: (context, day, focusedDay) => Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
              alignment: Alignment.center,
              child: Text('${day.day}', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ),
          ),
        ),
        if (_holidayFor(_selectedDay) case final holiday?)
          Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(holiday.name, style: const TextStyle(color: Color(0xFFEF4444))),
          )
        else if (_specialDayName(_selectedDay) case final name?)
          Container(
            width: double.infinity,
            color: Colors.amber.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(name, style: const TextStyle(color: Color(0xFFB45309))),
          ),
        if (_anniversaryNamesForDay(_selectedDay) case final names when names.isNotEmpty)
          Container(
            width: double.infinity,
            color: const Color(0xFFFCE7F3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              names.join(' / '),
              style: const TextStyle(color: Color(0xFFEC4899)),
            ),
          ),
        if (_weatherForDay(_selectedDay) case final weather?)
          InkWell(
            onTap: _openDetailedForecast,
            child: Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${weather.emoji} '
                      '${l10n.calendarWeatherLine(weather.maxTemp.round(), weather.minTemp.round())}'
                      '${weather.precipitationProbability != null ? l10n.calendarWeatherPrecipitation(weather.precipitationProbability!) : ''}',
                      style: const TextStyle(color: Color(0xFF2563EB)),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        const Divider(height: 1),
        selectedDaySchedules.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l10n.calendarNoScheduleThisDay)),
              )
            : _ScheduleListView(
                schedules: selectedDaySchedules,
                showDate: false,
                shrinkWrap: true,
              ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Schedule> schedules) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = schedules.where((s) => !s.startTime.isBefore(today)).toList();

    if (upcoming.isEmpty) {
      return Center(child: Text(l10n.calendarNoUpcoming));
    }
    return _ScheduleListView(schedules: upcoming, showDate: true);
  }
}

class _ScheduleListView extends StatelessWidget {
  final List<Schedule> schedules;
  final bool showDate;
  // true when embedded inside another scrollable (the calendar view), so it
  // must not try to scroll/size itself independently.
  final bool shrinkWrap;

  const _ScheduleListView({
    required this.schedules,
    required this.showDate,
    this.shrinkWrap = false,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final String timeLabel;
        if (schedule.isAllDay) {
          timeLabel = showDate
              ? '${_formatDate(schedule.startTime)}  ${l10n.calendarAllDay}'
              : l10n.calendarAllDay;
        } else {
          timeLabel = showDate
              ? '${_formatDate(schedule.startTime)}  ${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}'
              : '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}';
        }
        return ListTile(
          leading: Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: schedule.color, shape: BoxShape.circle),
          ),
          title: Text(schedule.title),
          subtitle: Text(timeLabel),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ScheduleDetailScreen(schedule: schedule)),
          ),
        );
      },
    );
  }
}
