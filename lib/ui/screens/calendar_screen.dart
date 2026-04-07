import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/calendar_events_repository.dart';
import '../../services/moments_repository.dart'
    show CoupleMoment, MomentsRepository;
import '../../services/user_repository.dart';
import '../../state/app_settings.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: user == null
          ? const SizedBox.shrink()
          : StreamBuilder(
              stream: context.read<UserRepository>().watchUser(user.uid),
              builder: (context, userSnap) {
                if (userSnap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '캘린더 정보를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }
                if (!userSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final coupleId = userSnap.data?.data()?['coupleId'] as String?;
                if (coupleId == null || coupleId.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.calendarNoCouple,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                return _CalendarBody(coupleId: coupleId);
              },
            ),
    );
  }
}

class _CalendarBody extends StatefulWidget {
  const _CalendarBody({required this.coupleId});

  final String coupleId;

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Set<DateTime> _markedMoments = {};
  Set<String> _markedMomentKeys = {};
  Map<DateTime, List<CoupleCalendarEvent>> _monthEvents = {};
  Map<String, List<String>> _monthPhotoUrlsByDay = {};
  List<CoupleMoment> _forDay = [];
  List<CoupleCalendarEvent> _eventsForDay = [];
  bool _loadingMonth = true;
  String? _loadErrorMessage;
  int _monthLoadSeq = 0;

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadMonth());
      unawaited(_loadDay(_selected!));
    });
  }

  Future<void> _loadMonth() async {
    final seq = ++_monthLoadSeq;
    setState(() => _loadingMonth = true);
    final momentRepo = context.read<MomentsRepository>();
    final eventRepo = context.read<CalendarEventsRepository>();
    try {
      final res = await Future.wait<dynamic>([
        momentRepo.loadDaysWithMomentsInMonth(widget.coupleId, _focused),
        eventRepo.loadEventsInMonth(widget.coupleId, _focused),
        momentRepo.loadPhotoUrlsByDayInMonth(widget.coupleId, _focused),
      ]);
      final set = res[0] as Set<DateTime>;
      final events = res[1] as List<CoupleCalendarEvent>;
      final photoUrlsByDay = res[2] as Map<String, List<String>>;
      final grouped = <DateTime, List<CoupleCalendarEvent>>{};
      for (final e in events) {
        final day = DateTime.parse('${e.dayKey}T00:00:00');
        grouped.putIfAbsent(day, () => <CoupleCalendarEvent>[]).add(e);
      }
      if (!mounted || seq != _monthLoadSeq) return;
      setState(() {
        _markedMoments = set;
        _markedMomentKeys = set.map(_dayKey).toSet();
        _monthEvents = grouped;
        _monthPhotoUrlsByDay = photoUrlsByDay;
        _loadErrorMessage = null;
        _loadingMonth = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted || seq != _monthLoadSeq) return;
      setState(() {
        _loadingMonth = false;
        _loadErrorMessage = e.code == 'failed-precondition'
            ? '캘린더 인덱스가 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요.'
            : '달력을 불러오지 못했어요. 네트워크를 확인해 주세요.';
      });
    } on StateError catch (e) {
      if (!mounted || seq != _monthLoadSeq) return;
      setState(() {
        _loadingMonth = false;
        _loadErrorMessage = e.message == 'calendar_index_missing_month'
            ? '캘린더 인덱스가 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요.'
            : '달력을 불러오지 못했어요. 네트워크를 확인해 주세요.';
      });
    } catch (_) {
      if (!mounted || seq != _monthLoadSeq) return;
      setState(() {
        _loadingMonth = false;
        _loadErrorMessage = '달력을 불러오지 못했어요. 네트워크를 확인해 주세요.';
      });
    }
  }

  Future<void> _loadDay(DateTime day) async {
    final momentRepo = context.read<MomentsRepository>();
    final eventRepo = context.read<CalendarEventsRepository>();
    try {
      final res = await Future.wait<dynamic>([
        momentRepo.loadMomentsForDay(widget.coupleId, day),
        eventRepo.loadEventsForDay(widget.coupleId, day),
      ]);
      final list = res[0] as List<CoupleMoment>;
      final events = res[1] as List<CoupleCalendarEvent>;
      if (!mounted) return;
      setState(() {
        _forDay = list;
        _eventsForDay = events;
        _loadErrorMessage = null;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = e.code == 'failed-precondition'
            ? '일정 조회 인덱스가 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요.'
            : '일정을 불러오지 못했어요. 다시 시도해 주세요.';
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = e.message == 'calendar_index_missing_day'
            ? '일정 조회 인덱스가 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요.'
            : '일정을 불러오지 못했어요. 다시 시도해 주세요.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = '일정을 불러오지 못했어요. 다시 시도해 주세요.';
      });
    }
  }

  Color _myColor(Color accent) => accent.withValues(alpha: 0.6);
  Color _partnerColor(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withHue((hsl.hue + 160) % 360)
        .withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.56);
  }

  bool _isMine(String uid) =>
      uid == (FirebaseAuth.instance.currentUser?.uid ?? '');

  static const _eventColors = <String, Color>{
    'rose': Color(0x66FF8FA3),
    'orange': Color(0x66FFB86B),
    'yellow': Color(0x66FFE082),
    'green': Color(0x6691E7B3),
    'blue': Color(0x668EC5FF),
    'purple': Color(0x66C8A4FF),
    'mint': Color(0x668DE9D1),
  };

  Color _eventColor(String key) => _eventColors[key] ?? _eventColors['rose']!;

  List<CoupleCalendarEvent> _eventsOnDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _monthEvents[d] ?? const <CoupleCalendarEvent>[];
  }

  List<String> _photoUrlsOnDay(DateTime day) =>
      _monthPhotoUrlsByDay[_dayKey(day)] ?? const <String>[];

  List<CoupleCalendarEvent> _sortedDayEvents() {
    final list = [..._eventsForDay];
    list.sort((a, b) {
      final ta = a.timeText;
      final tb = b.timeText;
      if (ta.isEmpty && tb.isNotEmpty) return 1;
      if (ta.isNotEmpty && tb.isEmpty) return -1;
      final byTime = ta.compareTo(tb);
      if (byTime != 0) return byTime;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  int _weeksInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final leading = first.weekday % 7;
    return ((leading + last.day) / 7).ceil();
  }

  Future<void> _openDayItemsSheet({
    required DateTime day,
    required Locale locale,
    required Color mineColor,
    required Color partnerColor,
  }) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final sortedEvents = _sortedDayEvents();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: (sortedEvents.isEmpty && _forDay.isEmpty)
                ? Center(
                    child: Text(
                      l10n.calendarEmptyBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final e in sortedEvents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ScheduleTemplateCard(
                            chipColor: _eventColor(e.colorKey),
                            timeText: e.timeText,
                            title: e.title,
                            note: e.note,
                            mine: _isMine(e.createdBy),
                            mineColor: mineColor,
                            partnerColor: partnerColor,
                            onTap: _isMine(e.createdBy)
                                ? () => _openEventSheet(day: day, editing: e)
                                : null,
                          ),
                        ),
                      for (final m in _forDay)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MomentTemplateCard(moment: m, locale: locale),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _openDayPhotoSheet({
    required DateTime day,
    required List<String> photoUrls,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  DateFormat('yyyy.MM.dd').format(day),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: photoUrls.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: photoUrls[i],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEventSheet({
    required DateTime day,
    CoupleCalendarEvent? editing,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final eventRepo = context.read<CalendarEventsRepository>();
    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final noteCtrl = TextEditingController(text: editing?.note ?? '');
    void disposeCtrls() {
      titleCtrl.dispose();
      noteCtrl.dispose();
    }

    var pickedDay = DateTime(day.year, day.month, day.day);
    var colorKey = editing?.colorKey ?? 'rose';
    TimeOfDay? pickedTime;
    if (editing != null && editing.timeText.contains(':')) {
      final parts = editing.timeText.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          pickedTime = TimeOfDay(hour: h, minute: m);
        }
      }
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing == null
                        ? l10n.calendarAddSchedule
                        : l10n.calendarEditSchedule,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: '제목'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: '내용'),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, c) {
                      const item = 28.0;
                      const count = 7.0;
                      final spacing =
                          ((c.maxWidth - (item * count)) / (count - 1)).clamp(
                            4.0,
                            18.0,
                          );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _eventColors.entries.map((e) {
                          final selected = colorKey == e.key;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: e.key == _eventColors.keys.last
                                  ? 0
                                  : spacing,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: () =>
                                  setModalState(() => colorKey = e.key),
                              child: Container(
                                width: item,
                                height: item,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: e.value,
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: pickedDay,
                              firstDate: DateTime(2020, 1, 1),
                              lastDate: DateTime(2035, 12, 31),
                            );
                            if (d != null) {
                              setModalState(() {
                                pickedDay = DateTime(d.year, d.month, d.day);
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(
                            DateFormat('M.d (E)', 'ko').format(pickedDay),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime:
                                  pickedTime ??
                                  const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (t != null) {
                              setModalState(() => pickedTime = t);
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(
                            pickedTime == null
                                ? l10n.calendarPickTime
                                : MaterialLocalizations.of(
                                    context,
                                  ).formatTimeOfDay(
                                    pickedTime!,
                                    alwaysUse24HourFormat: true,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (editing != null && _isMine(editing.createdBy))
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: Text(
                            l10n.commonDelete,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.calendarCancel),
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.calendarSave),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (saved == null && editing != null && _isMine(editing.createdBy)) {
      if (!mounted) return;
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.commonDelete),
          content: Text(l10n.calendarDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      );
      if (shouldDelete != true) {
        disposeCtrls();
        return;
      }
      try {
        await eventRepo.deleteEvent(
          coupleId: widget.coupleId,
          eventId: editing.id,
        );
        await _loadMonth();
        await _loadDay(_selected ?? pickedDay);
      } on FirebaseException catch (e) {
        if (!mounted) {
          disposeCtrls();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'permission-denied'
                  ? l10n.diaryFirestorePermissionDenied
                  : (e.code == 'failed-precondition'
                        ? '캘린더 인덱스가 아직 준비되지 않았어요.'
                        : '일정 삭제에 실패했어요. 다시 시도해 주세요.'),
            ),
          ),
        );
      } catch (_) {
        if (!mounted) {
          disposeCtrls();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.diaryFirestorePermissionDenied)),
        );
      }
      disposeCtrls();
      return;
    }
    if (saved != true) {
      disposeCtrls();
      return;
    }
    final timeText = pickedTime == null
        ? ''
        : '${pickedTime!.hour.toString().padLeft(2, '0')}:${pickedTime!.minute.toString().padLeft(2, '0')}';
    try {
      if (editing == null) {
        await eventRepo.addEvent(
          coupleId: widget.coupleId,
          day: pickedDay,
          title: titleCtrl.text,
          note: noteCtrl.text,
          timeText: timeText,
          colorKey: colorKey,
          shapeKey: 'dot',
        );
      } else {
        await eventRepo.updateEvent(
          coupleId: widget.coupleId,
          eventId: editing.id,
          title: titleCtrl.text,
          note: noteCtrl.text,
          day: pickedDay,
          timeText: timeText,
          colorKey: colorKey,
          shapeKey: 'dot',
        );
      }
      await _loadMonth();
      await _loadDay(_selected ?? pickedDay);
    } on FirebaseException catch (e) {
      if (!mounted) {
        disposeCtrls();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? l10n.diaryFirestorePermissionDenied
                : (e.code == 'failed-precondition'
                      ? '캘린더 인덱스가 아직 준비되지 않았어요.'
                      : '일정 저장에 실패했어요. 다시 시도해 주세요.'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        disposeCtrls();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diaryFirestorePermissionDenied)),
      );
    }
    disposeCtrls();
  }

  Widget _buildCalendarCell(
    BuildContext context,
    DateTime day, {
    required bool isOutside,
    required bool isSelected,
    required bool isToday,
    required bool compact,
    required Color accent,
  }) {
    final events = _eventsOnDay(day);
    final photoUrls = _photoUrlsOnDay(day);
    final hasPhoto = photoUrls.isNotEmpty;
    final hasSchedule = events.isNotEmpty;
    final dayColor = isOutside
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.onSurface;
    final bgColor = isToday
        ? accent.withValues(alpha: 0.1)
        : Colors.transparent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          if (hasPhoto)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: photoUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          if (hasPhoto)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0x66000000)],
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 1),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.9)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (hasPhoto ? Colors.white : dayColor),
                  fontWeight: FontWeight.w800,
                  shadows: hasPhoto
                      ? const [
                          Shadow(
                            color: Color(0xAA000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          if (hasSchedule)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: compact ? 6 : 7,
                height: compact ? 6 : 7,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: hasPhoto ? Colors.white : accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickMonthYear() async {
    var selectedYear = _focused.year;
    var selectedMonth = _focused.month;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (var y = 2020; y <= 2035; y++)
                              DropdownMenuItem(value: y, child: Text('$y년')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModal(() => selectedYear = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (var m = 1; m <= 12; m++)
                              DropdownMenuItem(value: m, child: Text('$m월')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModal(() => selectedMonth = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        ctx,
                        DateTime(selectedYear, selectedMonth, 1),
                      ),
                      child: const Text('이 달로 이동'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    final nextFocused = DateTime(picked.year, picked.month, 1);
    final currentSelected = _selected ?? picked;
    final clampedDay = currentSelected.day.clamp(
      1,
      DateUtils.getDaysInMonth(nextFocused.year, nextFocused.month),
    );
    final nextSelected = DateTime(
      nextFocused.year,
      nextFocused.month,
      clampedDay,
    );
    setState(() {
      _focused = nextFocused;
      _selected = nextSelected;
    });
    await _loadMonth();
    await _loadDay(nextSelected);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.select<AppSettings, Color>((s) => s.accentColor);
    final mineColor = _myColor(accent);
    final partnerColor = _partnerColor(accent);
    final locale = Locale(
      context.select<AppSettings, String>((s) => s.languageCode),
    );
    final screenW = MediaQuery.sizeOf(context).width;
    final compactCell = screenW < 360;
    final weekCount = _weeksInMonth(_focused);
    final rowHeight = weekCount >= 6
        ? (compactCell ? 74.0 : 84.0)
        : (compactCell ? 88.0 : 102.0);

    return Stack(
      children: [
        Column(
          children: [
            if (_loadingMonth && _markedMoments.isEmpty && _monthEvents.isEmpty)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    child: TableCalendar<dynamic>(
                      firstDay: DateTime(2020, 1, 1),
                      lastDay: DateTime(2035, 12, 31),
                      focusedDay: _focused,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      pageAnimationDuration: const Duration(milliseconds: 320),
                      pageAnimationCurve: Curves.easeOutCubic,
                      rowHeight: rowHeight,
                      locale: locale.languageCode,
                      selectedDayPredicate: (d) =>
                          _selected != null && isSameDay(_selected, d),
                      headerStyle: HeaderStyle(
                        titleCentered: false,
                        formatButtonVisible: false,
                        titleTextStyle: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      onHeaderTapped: (focusedDay) async {
                        await _pickMonthYear();
                      },
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: true,
                        defaultTextStyle: Theme.of(
                          context,
                        ).textTheme.bodyMedium!,
                        todayDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                      eventLoader: (day) {
                        final d = DateTime(day.year, day.month, day.day);
                        final events =
                            _monthEvents[d] ?? const <CoupleCalendarEvent>[];
                        final hasMoment = _markedMomentKeys.contains(
                          _dayKey(d),
                        );
                        if (!hasMoment && events.isEmpty) return const [];
                        return [...events, if (hasMoment) 'moment'];
                      },
                      calendarBuilders: CalendarBuilders<dynamic>(
                        defaultBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(
                              context,
                              day,
                              isOutside: false,
                              isSelected:
                                  _selected != null &&
                                  isSameDay(_selected, day),
                              isToday: isSameDay(DateTime.now(), day),
                              compact: compactCell,
                              accent: accent,
                            ),
                        outsideBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(
                              context,
                              day,
                              isOutside: true,
                              isSelected: false,
                              isToday: false,
                              compact: compactCell,
                              accent: accent,
                            ),
                        selectedBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(
                              context,
                              day,
                              isOutside: false,
                              isSelected: true,
                              isToday: false,
                              compact: compactCell,
                              accent: accent,
                            ),
                        todayBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(
                              context,
                              day,
                              isOutside: false,
                              isSelected:
                                  _selected != null &&
                                  isSameDay(_selected, day),
                              isToday: true,
                              compact: compactCell,
                              accent: accent,
                            ),
                        markerBuilder: (context, day, events) =>
                            const SizedBox.shrink(),
                      ),
                      onDaySelected: (selected, focused) async {
                        setState(() {
                          _selected = selected;
                          _focused = focused;
                        });
                        await _loadDay(selected);
                        if (!mounted) return;
                        final dayPhotos = <String>[
                          for (final m in _forDay) ...m.imageUrls,
                        ];
                        final fallbackPhotos = _photoUrlsOnDay(selected);
                        final photosToShow = dayPhotos.isNotEmpty
                            ? dayPhotos
                            : fallbackPhotos;
                        if (photosToShow.isNotEmpty) {
                          await _openDayPhotoSheet(
                            day: selected,
                            photoUrls: photosToShow,
                          );
                        } else {
                          await _openDayItemsSheet(
                            day: selected,
                            locale: locale,
                            mineColor: mineColor,
                            partnerColor: partnerColor,
                          );
                        }
                      },
                      onPageChanged: (focused) async {
                        if (!mounted) return;
                        setState(() => _focused = focused);
                        await _loadMonth();
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (_loadErrorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loadErrorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _loadMonth();
                        await _loadDay(_selected ?? DateTime.now());
                      },
                      child: const Text('재시도'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
          ],
        ),
        Positioned(
          right: 18,
          bottom: 18,
          child: FloatingActionButton(
            onPressed: () => _openEventSheet(day: _selected ?? DateTime.now()),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _ScheduleTemplateCard extends StatelessWidget {
  const _ScheduleTemplateCard({
    required this.chipColor,
    required this.timeText,
    required this.title,
    required this.note,
    required this.mine,
    required this.mineColor,
    required this.partnerColor,
    this.onTap,
  });

  final Color chipColor;
  final String timeText;
  final String title;
  final String note;
  final bool mine;
  final Color mineColor;
  final Color partnerColor;
  final VoidCallback? onTap;

  IconData _iconForTitle() {
    final t = title.toLowerCase();
    if (t.contains('병원') || t.contains('치과') || t.contains('검진')) {
      return Icons.local_hospital_outlined;
    }
    if (t.contains('여행') || t.contains('비행') || t.contains('trip')) {
      return Icons.flight_takeoff_rounded;
    }
    if (t.contains('데이트') || t.contains('기념일') || t.contains('anniversary')) {
      return Icons.favorite_border_rounded;
    }
    if (t.contains('운동') || t.contains('헬스') || t.contains('러닝')) {
      return Icons.fitness_center_rounded;
    }
    if (t.contains('회의') || t.contains('미팅') || t.contains('meeting')) {
      return Icons.work_outline_rounded;
    }
    return Icons.event_note_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = mine ? mineColor : partnerColor;
    final tilt = ((title.hashCode % 7) - 3) / 650.0;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Transform.rotate(
        angle: tilt,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: chipColor.withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: chipColor.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _iconForTitle(),
                          size: 15,
                          color: chipColor.withValues(alpha: 0.95),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (timeText.isNotEmpty)
                          Text(
                            timeText,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentTemplateCard extends StatelessWidget {
  const _MomentTemplateCard({required this.moment, required this.locale});

  final CoupleMoment moment;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = moment.imageUrls.isNotEmpty;
    final hasText = moment.caption.trim().isNotEmpty;
    final title = hasText ? moment.caption : '오늘의 기록';
    final stateLabel = hasPhoto && hasText
        ? '사진 + 글'
        : hasPhoto
        ? '사진'
        : '글';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                stateLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: Image.network(
                    moment.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                ),
              ),
            ],
            if (hasText) ...[
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat.Hm(locale.toString()).format(moment.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
