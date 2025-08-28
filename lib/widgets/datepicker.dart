import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showGlassDatePickerMacOS({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Pilih Tanggal',
  bool weekStartsMonday = true,
}) {
  firstDate ??= DateTime(2022);
  lastDate ??= DateTime(2100);

  return showGeneralDialog<DateTime?>(
    context: context,
    barrierLabel: 'date',
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.12),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, a1, a2, _) {
      final scale = Tween(begin: 0.98, end: 1.0)
          .transform(Curves.easeOutCubic.transform(a1.value));
      final opacity =
          CurvedAnimation(parent: a1, curve: Curves.easeOutCubic).value;
      return Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Center(
            child: _GlassDatePickerBodyV2(
              title: title,
              initialDate: initialDate,
              firstDate: firstDate!,
              lastDate: lastDate!,
              weekStartsMonday: weekStartsMonday,
            ),
          ),
        ),
      );
    },
  );
}

class _GlassDatePickerBodyV2 extends StatefulWidget {
  final String title;
  final DateTime initialDate, firstDate, lastDate;
  final bool weekStartsMonday;
  const _GlassDatePickerBodyV2({
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.weekStartsMonday,
  });

  @override
  State<_GlassDatePickerBodyV2> createState() => _GlassDatePickerBodyV2State();
}

class _GlassDatePickerBodyV2State extends State<_GlassDatePickerBodyV2> {
  late DateTime _cursor;
  late DateTime _temp;

  @override
  void initState() {
    _cursor = DateTime(widget.initialDate.year, widget.initialDate.month);
    _temp = widget.initialDate;
    super.initState();
  }

  bool _disabled(DateTime d) =>
      d.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month,
          widget.firstDate.day)) ||
      d.isAfter(DateTime(
          widget.lastDate.year, widget.lastDate.month, widget.lastDate.day));

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  List<DateTime?> _buildGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final wd = first.weekday;
    final startIndex = widget.weekStartsMonday ? 1 : 7;
    final leading = (wd - startIndex) % 7;
    final days = _daysInMonth(month);
    final cells = List<DateTime?>.filled(42, null);
    for (int i = 0; i < days; i++) {
      cells[leading + i] = DateTime(month.year, month.month, i + 1);
    }
    return cells;
  }

  void _prev() => setState(() {
        final m = _cursor.month == 1 ? 12 : _cursor.month - 1;
        final y = _cursor.month == 1 ? _cursor.year - 1 : _cursor.year;
        _cursor = DateTime(y, m);
      });
  void _next() => setState(() {
        final m = _cursor.month == 12 ? 1 : _cursor.month + 1;
        final y = _cursor.month == 12 ? _cursor.year + 1 : _cursor.year;
        _cursor = DateTime(y, m);
      });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0A84FF);
    final dfBig = DateFormat('EEE,\nMMM d');
    final monthTitle = DateFormat('MMMM yyyy');

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.42),
                const Color(0xFFEFF6FF).withOpacity(0.70),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 40,
                  offset: const Offset(0, 18)),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: Text('Batal',
                              style: TextStyle(color: Colors.blue.shade700)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => Navigator.pop(context, _temp),
                          child: const Text('Pilih'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(height: 1, color: Colors.white.withOpacity(0.10)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1),
                            ),
                          ),
                          child: Text(
                            dfBig.format(_temp),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  height: 1.05,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _prev,
                                    icon: const Icon(
                                        CupertinoIcons.chevron_left,
                                        color: Colors.black87),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        monthTitle.format(_cursor),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _next,
                                    icon: const Icon(
                                        CupertinoIcons.chevron_right,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _WeekHeader(
                                  weekStartsMonday: widget.weekStartsMonday),
                              const SizedBox(height: 6),
                              _CalendarGridV2(
                                cells: _buildGrid(_cursor),
                                selected: _temp,
                                isDisabled: _disabled,
                                onPick: (d) => setState(() => _temp = d),
                                accent: accent,
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    final now = DateTime.now();
                                    final today =
                                        DateTime(now.year, now.month, now.day);
                                    if (!_disabled(today)) {
                                      setState(() {
                                        _cursor =
                                            DateTime(today.year, today.month);
                                        _temp = today;
                                      });
                                    }
                                  },
                                  child: Text('Hari ini',
                                      style: TextStyle(
                                          color: Colors.blue.shade700)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarGridV2 extends StatelessWidget {
  final List<DateTime?> cells;
  final DateTime selected;
  final bool Function(DateTime) isDisabled;
  final void Function(DateTime) onPick;
  final Color accent;
  const _CalendarGridV2({
    required this.cells,
    required this.selected,
    required this.isDisabled,
    required this.onPick,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final dayStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: List.generate(6, (row) {
        return Row(
          children: List.generate(7, (col) {
            final idx = row * 7 + col;
            final d = cells[idx];
            final isSel = d != null &&
                d.year == selected.year &&
                d.month == selected.month &&
                d.day == selected.day;
            final disabled = d == null || isDisabled(d);
            return Expanded(
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Opacity(
                    opacity: d == null ? 0.0 : (disabled ? 0.35 : 1),
                    child: Material(
                      color: isSel ? accent : Colors.white.withOpacity(0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSel
                              ? accent.withOpacity(0.95)
                              : Colors.white.withOpacity(0.10),
                          width: isSel ? 1.2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap:
                            (d != null && !disabled) ? () => onPick(d) : null,
                        child: Center(
                          child: Text(
                            d?.day.toString() ?? '',
                            style: dayStyle?.copyWith(
                              color: isSel ? Colors.white : Colors.black87,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final bool weekStartsMonday;
  const _WeekHeader({required this.weekStartsMonday});
  @override
  Widget build(BuildContext context) {
    const labelsSun = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const labelsMon = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final labels = weekStartsMonday ? labelsMon : labelsSun;
    return Row(
      children: List.generate(7, (i) {
        return Expanded(
          child: Center(
            child: Text(labels[i],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.black.withOpacity(0.6),
                    )),
          ),
        );
      }),
    );
  }
}
