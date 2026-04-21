import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/couple_repository.dart';
import '../../services/moments_repository.dart' show MomentsRepository;
import '../../services/user_repository.dart';
import '../../state/app_settings.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          l10n.calendarTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: user == null
          ? const SizedBox.shrink()
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: context.read<UserRepository>().watchUser(user.uid),
              builder: (context, userSnap) {
                final coupleId = userSnap.data?.data()?['coupleId'] as String?;
                if (coupleId == null || coupleId.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.calendarNoCouple,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                  );
                }
                return _CalendarBody(coupleId: coupleId, myUid: user.uid);
              },
            ),
    );
  }
}

class _CalendarBody extends StatefulWidget {
  const _CalendarBody({required this.coupleId, required this.myUid});

  final String coupleId;
  final String myUid;

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  Set<DateTime> _momentDays = {};
  Map<DateTime, String> _anniversaryByDay = {};
  Map<DateTime, String> _birthdayByDay = {};

  bool _loading = true;
  String? _error;

  bool? _lastCalendarShowAnniversaries;
  bool? _lastCalendarShowBirthdays;

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadMonth());
    });
  }

  DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 커플 문서의 연애 시작일: `startDate` → `relationshipStart` → `createdAt`
  DateTime? _parseCoupleStart(Map<String, dynamic>? data) {
    if (data == null) return null;
    Timestamp? ts = data['startDate'] as Timestamp?;
    ts ??= data['relationshipStart'] as Timestamp?;
    ts ??= data['createdAt'] as Timestamp?;
    if (ts == null) return null;
    return DateUtils.dateOnly(ts.toDate());
  }

  String? _anniversaryLabelForDay(
    DateTime day,
    DateTime start,
    AppLocalizations l10n,
  ) {
    final d = _strip(day);
    if (d.isBefore(start)) return null;
    final daysSince = d.difference(start).inDays;
    if (daysSince <= 0) return null;
    if (daysSince % 365 == 0) {
      final y = daysSince ~/ 365;
      return y == 1
          ? l10n.calendarAnniversaryFirstYear
          : l10n.calendarAnniversaryYear(y);
    }
    if (daysSince % 100 == 0) {
      return l10n.calendarAnniversaryHundredDays(daysSince);
    }
    return null;
  }

  Future<void> _loadBirthdaysForMonth(
    DateTime month,
    List<String> memberIds,
    Map<DateTime, String> out,
    AppLocalizations l10n,
  ) async {
    final userRepo = context.read<UserRepository>();
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    for (final uid in memberIds) {
      if (uid.isEmpty) continue;
      final snap = await userRepo.ref(uid).get();
      final m = snap.data();
      if (m == null) continue;
      final bm = (m['birthMonth'] as num?)?.toInt();
      final bd = (m['birthDay'] as num?)?.toInt();
      if (bm == null || bd == null) continue;
      if (bm < 1 || bm > 12 || bd < 1 || bd > 31) continue;
      if (month.month != bm) continue;
      final dayDate = DateTime(month.year, month.month, bd);
      if (dayDate.month != bm || dayDate.day != bd) continue;
      if (dayDate.isBefore(first) || dayDate.isAfter(last)) continue;

      final label = uid == widget.myUid
          ? l10n.calendarBirthdayMine
          : l10n.calendarBirthdayPartner;
      final key = _strip(dayDate);
      out[key] = label;
    }
  }

  Future<void> _loadMonth() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    final momentRepo = context.read<MomentsRepository>();
    final coupleRepo = context.read<CoupleRepository>();
    final settings = context.read<AppSettings>();

    try {
      final momentDays = await momentRepo.loadDaysWithMomentsInMonth(
        widget.coupleId,
        _focused,
      );
      final coupleSnap = await coupleRepo.getCouple(widget.coupleId);
      final start = _parseCoupleStart(coupleSnap.data());

      final anniversaries = <DateTime, String>{};
      if (settings.calendarShowAnniversaries && start != null) {
        final first = DateTime(_focused.year, _focused.month, 1);
        final last = DateTime(_focused.year, _focused.month + 1, 0);
        for (var i = 0; i < last.day; i++) {
          final day = DateTime(first.year, first.month, i + 1);
          final label = _anniversaryLabelForDay(day, start, l10n);
          if (label != null) {
            anniversaries[_strip(day)] = label;
          }
        }
      }

      final birthdays = <DateTime, String>{};
      if (settings.calendarShowBirthdays) {
        final members = List<String>.from(
          coupleSnap.data()?['memberIds'] as List<dynamic>? ?? const [],
        );
        await _loadBirthdaysForMonth(_focused, members, birthdays, l10n);
      }

      if (!mounted) return;
      setState(() {
        _momentDays = momentDays.map(_strip).toSet();
        _anniversaryByDay = anniversaries;
        _birthdayByDay = birthdays;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _hasMoment(DateTime day) => _momentDays.contains(_strip(day));

  String? _anniversaryText(DateTime day) => _anniversaryByDay[_strip(day)];

  String? _birthdayText(DateTime day) => _birthdayByDay[_strip(day)];

  Widget _markerForDay(DateTime day) {
    final hasMoment = _hasMoment(day);
    final ann = _anniversaryText(day);
    final birth = _birthdayText(day);

    if (hasMoment && ann != null) {
      return SizedBox(
        height: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.favorite, size: 20, color: Colors.black),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                ann,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (ann != null) {
      return Text(
        ann,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (hasMoment) {
      return const Icon(Icons.favorite, size: 14, color: Colors.black);
    }

    if (birth != null) {
      return Text(
        birth,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return const SizedBox(height: 22);
  }

  Widget _dayCell(
    BuildContext context,
    DateTime day, {
    required bool isOutside,
    required bool isSelected,
    required bool isToday,
  }) {
    final dayColor = isOutside ? Colors.black38 : Colors.black;
    final bg = isToday ? const Color(0xFFF0F0F0) : Colors.transparent;
    final border = isSelected ? Border.all(color: Colors.black, width: 1.5) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              color: dayColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          _markerForDay(day),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final l10n = AppLocalizations.of(context)!;
    final locale = Locale(settings.languageCode);

    final ann = settings.calendarShowAnniversaries;
    final birth = settings.calendarShowBirthdays;
    if (_lastCalendarShowAnniversaries != null &&
        (_lastCalendarShowAnniversaries != ann ||
            _lastCalendarShowBirthdays != birth)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadMonth());
      });
    }
    _lastCalendarShowAnniversaries = ann;
    _lastCalendarShowBirthdays = birth;

    return Column(
      children: [
        if (_loading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: Colors.black,
            backgroundColor: Color(0xFFEEEEEE),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.calendarLoadError,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => unawaited(_loadMonth()),
                  child: Text(l10n.calendarRetry),
                ),
              ],
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: TableCalendar<void>(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focused,
              locale: locale.languageCode,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              rowHeight: 78,
              selectedDayPredicate: (d) =>
                  _selected != null && isSameDay(_selected, d),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selected = selected;
                  _focused = focused;
                });
              },
              onPageChanged: (focused) {
                _focused = focused;
                unawaited(_loadMonth());
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black),
                rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: true,
                cellMargin: EdgeInsets.zero,
                defaultDecoration: BoxDecoration(),
                weekendDecoration: BoxDecoration(),
                holidayDecoration: BoxDecoration(),
                todayDecoration: BoxDecoration(),
                selectedDecoration: BoxDecoration(),
                markersMaxCount: 0,
              ),
              calendarBuilders: CalendarBuilders<void>(
                defaultBuilder: (context, day, focused) => _dayCell(
                  context,
                  day,
                  isOutside: false,
                  isSelected: _selected != null && isSameDay(_selected, day),
                  isToday: isSameDay(DateTime.now(), day),
                ),
                outsideBuilder: (context, day, focused) => _dayCell(
                  context,
                  day,
                  isOutside: true,
                  isSelected: false,
                  isToday: false,
                ),
                selectedBuilder: (context, day, focused) => _dayCell(
                  context,
                  day,
                  isOutside: false,
                  isSelected: true,
                  isToday: false,
                ),
                todayBuilder: (context, day, focused) => _dayCell(
                  context,
                  day,
                  isOutside: false,
                  isSelected: _selected != null && isSameDay(_selected, day),
                  isToday: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
