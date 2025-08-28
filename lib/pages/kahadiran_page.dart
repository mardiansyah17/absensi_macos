import 'dart:ui';

import 'package:face_client/datasource/remote_datasource.dart';
import 'package:face_client/models/attendance.dart';
import 'package:face_client/pages/absen_page.dart';
import 'package:face_client/services/to_csv.dart';
import 'package:face_client/widgets/datepicker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';

class KahadiranPage extends StatefulWidget {
  const KahadiranPage({super.key});

  @override
  State<KahadiranPage> createState() => _KahadiranPageState();
}

class _KahadiranPageState extends State<KahadiranPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  List<Attendance> _attendances = [];

  int presentCount = 0;
  int lateCount = 0;
  int excusedCount = 0;

  @override
  void initState() {
    super.initState();
    getAttedance();
  }

  void getAttedance() async {
    context.loaderOverlay.show();
    await RemoteDatasource()
        .getAttendances(date: dateFormat.format(_selectedDate))
        .then((attendances) {
      setState(() {
        _attendances = attendances;
        presentCount = attendances
            .where((a) => a.status == AttendanceStatus.present)
            .length;
        lateCount =
            attendances.where((a) => a.status == AttendanceStatus.late).length;
        excusedCount = attendances
            .where((a) => a.status == AttendanceStatus.excused)
            .length;
      });
      context.loaderOverlay.hide();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF2FF), Color(0xFFFFFFFF)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _GlassToolbar(
                  child: _buildToolbar(context),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _StatCard(
                                  title: 'Hadir',
                                  value: "$presentCount",
                                  icon: CupertinoIcons.checkmark_seal),
                              _StatCard(
                                  title: 'Terlambat',
                                  value: "$lateCount",
                                  icon: CupertinoIcons.timer),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTableCard(context, _attendances),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.calendar, size: 18),
        const SizedBox(width: 8),
        Text(
          'Kehadiran',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.8),
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 12),
        _PrimaryButton(
          icon: CupertinoIcons.camera_viewfinder,
          label: 'Absensi Wajah',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AttendanceHomePage()),
            );
          },
        ),
        const SizedBox(width: 4),
        _GhostButton(
          icon: CupertinoIcons.square_arrow_down,
          label: 'Export',
          onPressed: () async {
            final header = [
              'Nama',
              'Departemen',
              'Masuk',
              'Pulang',
              'Status',
            ];
            final rows = _attendances.map((a) {
              return [
                a.employe.name,
                a.employe.department?.name ?? '-',
                a.checkIn ?? '-',
                a.checkOut ?? '-',
                a.status.label,
              ];
            }).toList();

            try {
              final savedPath = await saveCsvWithDialogOrFallback(
                header: header,
                rows: rows,
                suggestedFileName:
                    'kehadiran_${dateFormat.format(_selectedDate)}.csv',
              );

              await revealInFinder(savedPath);

              print('File tersimpan: $savedPath');
            } catch (e) {
              print('Gagal menyimpan: $e');
            }
          },
        ),
      ],
    );
  }

  Widget _buildTableCard(BuildContext context, List<Attendance> attendances) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.table_badge_more, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Daftar Kehadiran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Spacer(),
              _GhostButton(
                icon: CupertinoIcons.calendar_badge_plus,
                label: dateFormat.format(_selectedDate),
                onPressed: () async {
                  final picked = await showGlassDatePickerMacOS(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2100),
                    title: 'Pilih Tanggal',
                  );

                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    getAttedance();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DataTableMac(
            rows: attendances,
          ),
        ],
      ),
    );
  }

  void _onSearch() {
    setState(() {});
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Lanjutan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                const Spacer(),
                _PrimaryButton(
                  icon: CupertinoIcons.checkmark_circle,
                  label: 'Terapkan',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassToolbar extends StatelessWidget {
  const _GlassToolbar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            border: Border(
                bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 6),
                blurRadius: 16,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ).merge(
        ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final isPressed = states.contains(WidgetState.pressed);
            return isPressed ? const Color(0xFF1E4FD1) : null;
          }),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton(
      {required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.black.withOpacity(0.12)),
        foregroundColor: Colors.black.withOpacity(0.85),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _MacTextField extends StatelessWidget {
  const _MacTextField({
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.width,
  });
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onSubmitted;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );

    return width != null ? SizedBox(width: width, child: field) : field;
  }
}

class _RangeSegmentedControl extends StatelessWidget {
  const _RangeSegmentedControl(
      {required this.value, required this.onChanged, required this.segments});
  final int value;
  final ValueChanged<int> onChanged;
  final Map<int, String> segments;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: value,
        children: {
          for (final e in segments.entries)
            e.key: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(e.value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: _GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child:
                  const Icon(CupertinoIcons.checkmark_alt, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.65), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataTableMac extends StatelessWidget {
  const _DataTableMac({required this.rows});
  final List<Attendance> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final table = DataTable(
        showCheckboxColumn: false,
        headingTextStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        dataTextStyle: const TextStyle(fontSize: 13),
        headingRowColor: WidgetStatePropertyAll(Colors.white.withOpacity(0.8)),
        columns: const [
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Departemen')),
          DataColumn(label: Text('Masuk')),
          DataColumn(label: Text('Pulang')),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          for (final r in rows)
            DataRow(
              onSelectChanged: (_) {},
              cells: [
                DataCell(Row(
                  children: [
                    CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            const Color(0xFF2563EB).withOpacity(0.12),
                        child: Text(r.employe.name.isNotEmpty
                            ? r.employe.name[0]
                            : '?')),
                    const SizedBox(width: 8),
                    Text(r.employe.name),
                  ],
                )),
                DataCell(Text(r.employe.department?.name ?? "-")),
                DataCell(Text(r.checkIn ?? "-")),
                DataCell(Text(r.checkOut ?? "-")),
                DataCell(_StatusTag(status: r.status)),
              ],
            ),
        ],
      );

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth),
          child: table,
        ),
      );
    });
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      AttendanceStatus.present => (
          const Color(0xFFDCFCE7),
          const Color(0xFF166534)
        ),
      AttendanceStatus.late => (
          const Color(0xFFFFF3CD),
          const Color(0xFF92400E)
        ),
      AttendanceStatus.excused => (
          const Color(0xFFE0F2FE),
          const Color(0xFF0284C7)
        ),
      AttendanceStatus.unexcused => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C)
        ),
      AttendanceStatus.absent => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280)
        ),
      _ => (Colors.white, Colors.black),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(status.label.toUpperCase(),
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

String _formatFullDate(DateTime d) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _formatWeekRange(DateTime d) {
  final start = d.subtract(Duration(days: d.weekday - 1));
  final end = start.add(const Duration(days: 6));
  return '${start.day}/${start.month} – ${end.day}/${end.month}/${end.year}';
}

String _formatMonth(DateTime d) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];
  return '${months[d.month - 1]} ${d.year}';
}
