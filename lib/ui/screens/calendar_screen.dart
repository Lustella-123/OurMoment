import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/moments_repository.dart';
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
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final coupleId = snap.data?.data()?['coupleId'] as String?;
                if (coupleId == null || coupleId.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.calendarNoCouple,
                        textAlign: TextAlign.center,
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
  DateTime? _selected = DateTime.now();
  Set<String> _markedMomentKeys = {};
  Map<String, List<String>> _monthPhotoUrlsByDay = {};
  List<CoupleMoment> _forDay = const [];
  bool _loadingMonth = true;
  String? _error;
  int _monthSeq = 0;

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadMonth());
      unawaited(_loadDay(_selected!));
    });
  }

  Future<void> _loadMonth() async {
    final seq = ++_monthSeq;
    setState(() => _loadingMonth = true);
    final repo = context.read<MomentsRepository>();
    try {
      final res = await Future.wait<dynamic>([
        repo.loadDaysWithMomentsInMonth(widget.coupleId, _focused),
        repo.loadPhotoUrlsByDayInMonth(widget.coupleId, _focused),
      ]);
      if (!mounted || seq != _monthSeq) return;
      final days = res[0] as Set<DateTime>;
      final photosByDay = res[1] as Map<String, List<String>>;
      setState(() {
        _markedMomentKeys = days.map(_dayKey).toSet();
        _monthPhotoUrlsByDay = photosByDay;
        _loadingMonth = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || seq != _monthSeq) return;
      setState(() {
        _loadingMonth = false;
        _error = '달력 데이터를 불러오지 못했어요.';
      });
    }
  }

  Future<void> _loadDay(DateTime day) async {
    final repo = context.read<MomentsRepository>();
    try {
      final moments = await repo.loadMomentsForDay(widget.coupleId, day);
      if (!mounted) return;
      setState(() {
        _forDay = moments;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '해당 날짜 기록을 불러오지 못했어요.');
    }
  }

  Future<void> _openPolaroids(DateTime day, Locale locale) async {
    final l10n = AppLocalizations.of(context)!;
    var page = 0;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        if (_forDay.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(child: Text(l10n.calendarEmptyBody)),
          );
        }
        return StatefulBuilder(
          builder: (context, setModal) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.78,
              child: Column(
                children: [
                  Text(
                    DateFormat('yyyy.MM.dd').format(day),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView.builder(
                      itemCount: _forDay.length,
                      onPageChanged: (index) => setModal(() => page = index),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                        child: _MomentTemplateCard(
                          moment: _forDay[index],
                          locale: locale,
                        ),
                      ),
                    ),
                  ),
                  if (_forDay.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _forDay.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: page == index ? 12 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: page == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    required bool isOutside,
    required bool isSelected,
    required bool isToday,
    required Color accent,
  }) {
    final photos = _monthPhotoUrlsByDay[_dayKey(day)] ?? const <String>[];
    final hasPhoto = photos.isNotEmpty;
    final dayColor = isOutside
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 3),
      decoration: BoxDecoration(
        color: isToday ? accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          if (hasPhoto)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: photos.first,
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
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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
        ],
      ),
    );
  }

  int _weeksInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final leading = first.weekday % 7;
    return ((leading + last.day) / 7).ceil();
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
                          // ignore: deprecated_member_use
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
                          // ignore: deprecated_member_use
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
    final selected = _selected ?? picked;
    final day = selected.day.clamp(
      1,
      DateUtils.getDaysInMonth(nextFocused.year, nextFocused.month),
    );
    final nextSelected = DateTime(nextFocused.year, nextFocused.month, day);
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
    final locale = Locale(
      context.select<AppSettings, String>((s) => s.languageCode),
    );
    final compactCell = MediaQuery.sizeOf(context).width < 360;
    final weekCount = _weeksInMonth(_focused);
    final rowHeight = weekCount >= 6
        ? (compactCell ? 74.0 : 84.0)
        : (compactCell ? 88.0 : 102.0);

    return Column(
      children: [
        if (_loadingMonth && _markedMomentKeys.isEmpty)
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
                    titleTextStyle: Theme.of(context).textTheme.headlineSmall!
                        .copyWith(fontWeight: FontWeight.w900),
                  ),
                  onHeaderTapped: (_) => _pickMonthYear(),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
                    todayDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                  eventLoader: (day) => _markedMomentKeys.contains(_dayKey(day))
                      ? const ['moment']
                      : const [],
                  calendarBuilders: CalendarBuilders<dynamic>(
                    defaultBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      isOutside: false,
                      isSelected:
                          _selected != null && isSameDay(_selected, day),
                      isToday: isSameDay(DateTime.now(), day),
                      accent: accent,
                    ),
                    outsideBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      isOutside: true,
                      isSelected: false,
                      isToday: false,
                      accent: accent,
                    ),
                    selectedBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      isOutside: false,
                      isSelected: true,
                      isToday: false,
                      accent: accent,
                    ),
                    todayBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      isOutside: false,
                      isSelected:
                          _selected != null && isSameDay(_selected, day),
                      isToday: true,
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
                    await _openPolaroids(selected, locale);
                  },
                  onPageChanged: (focused) async {
                    setState(() => _focused = focused);
                    await _loadMonth();
                  },
                ),
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
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
    final photos = moment.imageUrls;
    final previewCount = photos.length > 3 ? 3 : photos.length;
    final overflow = photos.length - previewCount;
    return Transform.rotate(
      angle: ((moment.id.hashCode % 9) - 4) / 700,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPhoto)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    if (previewCount == 1) {
                      return SizedBox(
                        height: width * 0.65,
                        child: _PolaroidImage(url: photos.first),
                      );
                    }
                    if (previewCount == 2) {
                      return SizedBox(
                        height: width * 0.62,
                        child: Row(
                          children: [
                            Expanded(child: _PolaroidImage(url: photos[0])),
                            const SizedBox(width: 6),
                            Expanded(child: _PolaroidImage(url: photos[1])),
                          ],
                        ),
                      );
                    }
                    return SizedBox(
                      height: width * 0.72,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _PolaroidImage(url: photos[0]),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(child: _PolaroidImage(url: photos[1])),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _PolaroidImage(url: photos[2]),
                                      if (overflow > 0)
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '+$overflow',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (hasText) ...[
                const SizedBox(height: 10),
                Text(
                  moment.caption.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
              if (!hasText && !hasPhoto)
                Text('기록 없음', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                DateFormat(
                  'yyyy.MM.dd HH:mm',
                  locale.toString(),
                ).format(moment.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolaroidImage extends StatelessWidget {
  const _PolaroidImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 700,
        memCacheHeight: 700,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
