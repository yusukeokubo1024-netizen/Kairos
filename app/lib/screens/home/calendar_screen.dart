import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/anniversary.dart';
import '../../models/schedule.dart';
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

  // Well-known annual observances that are not official Japanese public
  // holidays (so they don't get colored red), keyed by (month, day).
  static const _specialDays = <(int, int), String>{
    (12, 24): 'クリスマスイブ',
    (12, 25): 'クリスマス',
    (12, 31): '大晦日',
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

  bool _isHolidayOrSunday(DateTime day) {
    return day.weekday == DateTime.sunday || holiday_jp.isHoliday(day);
  }

  String? _specialDayName(DateTime day) {
    final fixed = _specialDays[(day.month, day.day)];
    if (fixed != null) return fixed;

    // 母の日 (5月第2日曜) and 父の日 (6月第3日曜) move every year, so they're
    // computed relative to `day.year` rather than stored as a fixed date.
    if (_isSameDay(day, _nthWeekdayOfMonth(day.year, 5, DateTime.sunday, 2))) {
      return '母の日';
    }
    if (_isSameDay(day, _nthWeekdayOfMonth(day.year, 6, DateTime.sunday, 3))) {
      return '父の日';
    }
    return null;
  }

  /// Names of the signed-in user's own anniversaries, plus friends'/family's
  /// birthdays (shared via groups), that fall on [day] this year.
  List<String> _anniversaryNamesForDay(DateTime day) {
    final names = <String>[];
    for (final anniversary in _anniversaries) {
      if (anniversary.month == day.month && anniversary.day == day.day) {
        names.add(anniversary.title);
      }
    }
    for (final birthday in _friendBirthdays) {
      if (birthday.month == day.month && birthday.day == day.day) {
        names.add('${birthday.name}の誕生日');
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

  /// Renders a day cell showing the day number and, for holidays, the
  /// holiday's name in small text underneath — used for today/selected/
  /// holiday cells so the name doesn't get hidden by those states.
  Widget _buildDayCell(
    BuildContext context, {
    required DateTime day,
    bool isToday = false,
    bool isSelected = false,
  }) {
    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (_isHolidayOrSunday(day)) {
      textColor = const Color(0xFFEF4444);
    } else if (day.weekday == DateTime.saturday) {
      textColor = const Color(0xFF2563EB);
    } else {
      textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    }

    final holidayName = holiday_jp.getHoliday(day)?.name;
    final anniversaryNames = _anniversaryNamesForDay(day);
    final labelName = holidayName ??
        (anniversaryNames.isNotEmpty ? anniversaryNames.first : null) ??
        _specialDayName(day);
    final labelColor = isSelected
        ? Colors.white
        : (holidayName != null
            ? const Color(0xFFEF4444)
            : (anniversaryNames.isNotEmpty ? const Color(0xFFEC4899) : const Color(0xFFB45309)));

    final weather = _weatherForDay(day);

    // Outer cell fills the whole grid square and draws the マス目 grid lines;
    // the inner circle is only for the today/selected highlight, and the
    // weather emoji sits in the corner so it never fights the circle for space.
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (weather != null)
            Positioned(
              top: 2,
              right: 2,
              child: Text(weather.emoji, style: const TextStyle(fontSize: 9)),
            ),
          Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          border: isToday && !isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${day.day}', style: TextStyle(color: textColor)),
            if (labelName != null)
              Text(
                labelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 7, color: labelColor),
              ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Future<void> _openMonthPicker(DateTime currentFocusedDay) async {
    var year = currentFocusedDay.year;
    var month = currentFocusedDay.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('年月を選択'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: year,
                items: [
                  for (var y = 2020; y <= 2035; y++)
                    DropdownMenuItem(value: y, child: Text('$y年')),
                ],
                onChanged: (value) => setDialogState(() => year = value!),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: month,
                items: [
                  for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text('$m月')),
                ],
                onChanged: (value) => setDialogState(() => month = value!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            FilledButton(
              onPressed: () => Navigator.pop(context, DateTime(year, month, 1)),
              child: const Text('移動'),
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
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('表示するカレンダー'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('個人の予定'),
                  value: !hidden.contains(null),
                  onChanged: (checked) {
                    setDialogState(() {
                      checked == true ? hidden.remove(null) : hidden.add(null);
                    });
                  },
                ),
                ...groups.map((group) {
                  return CheckboxListTile(
                    title: Text(group.name),
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
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final schedulesQuery = FirebaseFirestore.instance
        .collection('schedules')
        .where('participantIds', arrayContains: uid)
        .orderBy('startTime');
    final groupsQuery =
        FirebaseFirestore.instance.collection('sharedGroups').where('memberIds', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kairos'),
            Text(
              '一瞬の時間の共有',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
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
                tooltip: '表示するカレンダーを選ぶ',
                onPressed: () => _openCalendarFilter(groups),
              );
            },
          ),
          IconButton(
            icon: Icon(_viewMode == _ViewMode.calendar
                ? Icons.view_list_outlined
                : Icons.calendar_month_outlined),
            tooltip: _viewMode == _ViewMode.calendar ? '一覧で表示' : 'カレンダーで表示',
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
                      child: const Text(
                        '予定の読み込みに失敗しました',
                        style: TextStyle(color: Colors.red),
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
    final schedulesByDay = <DateTime, List<Schedule>>{};
    for (final schedule in schedules) {
      final day = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      schedulesByDay.putIfAbsent(day, () => []).add(schedule);
    }

    final selectedDaySchedules =
        schedules.where((s) => _isSameDay(s.startTime, _selectedDay)).toList();

    return Column(
      children: [
        TableCalendar<Schedule>(
          locale: 'ja_JP',
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
            formatButtonShowsNext: false,
          ),
          availableCalendarFormats: const {
            CalendarFormat.month: '月',
            CalendarFormat.week: '週',
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
          daysOfWeekHeight: 28,
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekendStyle: TextStyle(color: Color(0xFF2563EB)),
          ),
          calendarBuilders: CalendarBuilders<Schedule>(
            dowBuilder: (context, day) {
              // Sunday's day-of-week header should read in red like holidays,
              // not the Saturday blue that daysOfWeekStyle.weekendStyle gives it.
              if (day.weekday != DateTime.sunday) return null;
              final label = DateFormat.E('ja_JP').format(day);
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
              child: Text('${day.day}', style: TextStyle(color: Colors.grey.shade400)),
            ),
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(4).map((schedule) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(color: schedule.color, shape: BoxShape.circle),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        if (holiday_jp.getHoliday(_selectedDay) case final holiday?)
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
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              '${weather.emoji} 最高${weather.maxTemp.round()}° / 最低${weather.minTemp.round()}°',
              style: const TextStyle(color: Color(0xFF2563EB)),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: selectedDaySchedules.isEmpty
              ? const Center(child: Text('この日の予定はありません'))
              : _ScheduleListView(schedules: selectedDaySchedules, showDate: false),
        ),
      ],
    );
  }

  Widget _buildListView(List<Schedule> schedules) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = schedules.where((s) => !s.startTime.isBefore(today)).toList();

    if (upcoming.isEmpty) {
      return const Center(child: Text('今後の予定はありません'));
    }
    return _ScheduleListView(schedules: upcoming, showDate: true);
  }
}

class _ScheduleListView extends StatelessWidget {
  final List<Schedule> schedules;
  final bool showDate;

  const _ScheduleListView({required this.schedules, required this.showDate});

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
    return ListView.builder(
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final String timeLabel;
        if (schedule.isAllDay) {
          timeLabel = showDate ? '${_formatDate(schedule.startTime)}  終日' : '終日';
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
