import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

enum LeaveStatus { pending, approved, rejected }

enum LeaveType { tahunan, sakit, bersama, menikah, melahirkan, lainnya }

class LeaveRequest {
  final String id;
  final String employeeName;
  final String department;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final LeaveType type;
  final String reason;
  LeaveStatus status;
  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.department,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.type,
    required this.reason,
    this.status = LeaveStatus.pending,
  });
}

class PengajuanCutiPageMacOS extends StatefulWidget {
  const PengajuanCutiPageMacOS({super.key});
  @override
  State<PengajuanCutiPageMacOS> createState() => _PengajuanCutiPageMacOSState();
}

class _PengajuanCutiPageMacOSState extends State<PengajuanCutiPageMacOS> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  List<LeaveRequest> _all = [];
  List<LeaveRequest> _filtered = [];
  final Set<String> _selected = {};
  LeaveStatus? _statusFilter;
  LeaveType? _typeFilter;
  DateTimeRange? _range;
  String _sortField = 'tanggal';
  bool _sortAsc = false;
  int _rowsPerPage = 10;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _all = _seed();
    _applyFilters();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<LeaveRequest> out = List.of(_all);
    if (q.isNotEmpty) {
      out = out.where((e) {
        return e.employeeName.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q) ||
            e.reason.toLowerCase().contains(q) ||
            _labelType(e.type).toLowerCase().contains(q);
      }).toList();
    }
    if (_statusFilter != null) {
      out = out.where((e) => e.status == _statusFilter).toList();
    }
    if (_typeFilter != null) {
      out = out.where((e) => e.type == _typeFilter).toList();
    }
    if (_range != null) {
      out = out
          .where((e) => !(e.endDate.isBefore(_range!.start) ||
              e.startDate.isAfter(_range!.end)))
          .toList();
    }
    out.sort((a, b) {
      int c = 0;
      switch (_sortField) {
        case 'nama':
          c = a.employeeName.compareTo(b.employeeName);
          break;
        case 'dept':
          c = a.department.compareTo(b.department);
          break;
        case 'jenis':
          c = _labelType(a.type).compareTo(_labelType(b.type));
          break;
        case 'status':
          c = a.status.index.compareTo(b.status.index);
          break;
        case 'durasi':
          c = a.days.compareTo(b.days);
          break;
        default:
          c = a.startDate.compareTo(b.startDate);
      }
      return _sortAsc ? c : -c;
    });
    setState(() {
      _filtered = out;
      _page = 0;
      _selected.clear();
    });
  }

  void _approve(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      setState(() {
        _all[idx].status = LeaveStatus.approved;
      });
      _applyFilters();
    }
  }

  void _reject(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      setState(() {
        _all[idx].status = LeaveStatus.rejected;
      });
      _applyFilters();
    }
  }

  void _bulkApprove() {
    for (final id in _selected) {
      final idx = _all.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        _all[idx].status = LeaveStatus.approved;
      }
    }
    _applyFilters();
  }

  void _bulkReject() {
    for (final id in _selected) {
      final idx = _all.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        _all[idx].status = LeaveStatus.rejected;
      }
    }
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    final totalPages = (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);
    final start = _page * _rowsPerPage;
    final end = min(start + _rowsPerPage, _filtered.length);
    final pageRows =
        _filtered.isEmpty ? <LeaveRequest>[] : _filtered.sublist(start, end);
    return ColoredBox(
      color: const Color(0xFFF6F8FB),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Glass(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pengajuan Cuti',
                              style: base.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Kelola permohonan cuti karyawan',
                              style: base.bodyMedium
                                  ?.copyWith(color: Colors.black54)),
                        ],
                      ),
                    ),
                    _PrimaryButton(
                      label: 'Setujui Terpilih',
                      icon: Icons.check_circle,
                      onPressed: _selected.isEmpty ? null : _bulkApprove,
                    ),
                    const SizedBox(width: 12),
                    _GhostButton(
                      label: 'Tolak Terpilih',
                      icon: Icons.cancel,
                      onPressed: _selected.isEmpty ? null : _bulkReject,
                    ),
                    const SizedBox(width: 12),
                    _GhostButton(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () {
                        setState(() {});
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Glass(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => _applyFilters(),
                        decoration: InputDecoration(
                          hintText: 'Cari nama, departemen, alasan, jenis',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Segmented(
                      items: const [
                        ('Semua', null),
                        ('Pending', LeaveStatus.pending),
                        ('Disetujui', LeaveStatus.approved),
                        ('Ditolak', LeaveStatus.rejected),
                      ],
                      value: _statusFilter,
                      onChanged: (v) {
                        _statusFilter = v;
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: DropdownButton<LeaveType?>(
                          value: _typeFilter,
                          hint: const Text('Jenis Cuti'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Semua Jenis')),
                            ...LeaveType.values.map((e) => DropdownMenuItem(
                                value: e, child: Text(_labelType(e)))),
                          ],
                          onChanged: (v) {
                            _typeFilter = v;
                            _applyFilters();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GhostButton(
                      label: _range == null
                          ? 'Rentang Tanggal'
                          : _fmtRange(_range!),
                      icon: Icons.date_range,
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 2),
                          initialDateRange: _range,
                          helpText: 'Pilih Rentang Tanggal',
                        );
                        if (picked != null) {
                          _range = picked;
                          _applyFilters();
                        }
                      },
                    ),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: DropdownButton<int>(
                          value: _rowsPerPage,
                          items: const [10, 20, 50]
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text('Per Halaman: $e')))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _rowsPerPage = v);
                            _applyFilters();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _Glass(
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _HeaderRow(
                        allSelected: _selected.isNotEmpty &&
                            _selected.length == pageRows.length,
                        someSelected: _selected.isNotEmpty &&
                            _selected.length < pageRows.length,
                        onToggleAll: (v) {
                          setState(() {
                            if (v) {
                              _selected.addAll(pageRows.map((e) => e.id));
                            } else {
                              _selected.removeAll(pageRows.map((e) => e.id));
                            }
                          });
                        },
                        sortField: _sortField,
                        sortAsc: _sortAsc,
                        onSort: (f) {
                          if (_sortField == f) {
                            _sortAsc = !_sortAsc;
                          } else {
                            _sortField = f;
                            _sortAsc = true;
                          }
                          _applyFilters();
                        },
                      ),
                      const Divider(height: 1),
                      if (pageRows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                              child: Text('Tidak ada data',
                                  style: base.titleMedium
                                      ?.copyWith(color: Colors.black54))),
                        )
                      else
                        ...pageRows.map((e) => _DataRowCard(
                              data: e,
                              selected: _selected.contains(e.id),
                              onSelect: (v) {
                                setState(() {
                                  if (v) {
                                    _selected.add(e.id);
                                  } else {
                                    _selected.remove(e.id);
                                  }
                                });
                              },
                              onView: () => _showDetail(e),
                              onApprove: e.status == LeaveStatus.approved
                                  ? null
                                  : () => _approve(e.id),
                              onReject: e.status == LeaveStatus.rejected
                                  ? null
                                  : () => _reject(e.id),
                            )),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                                'Halaman ${_filtered.isEmpty ? 0 : _page + 1} dari $totalPages'),
                            const SizedBox(width: 12),
                            _GhostIcon(
                              icon: Icons.chevron_left,
                              onPressed: _page > 0
                                  ? () => setState(() => _page -= 1)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            _GhostIcon(
                              icon: Icons.chevron_right,
                              onPressed: (_page + 1) < totalPages
                                  ? () => setState(() => _page += 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(LeaveRequest e) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        final base = Theme.of(ctx).textTheme;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 240, vertical: 80),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: const SizedBox.expand()),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text('Detail Pengajuan',
                                  style: base.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700))),
                          IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        runSpacing: 12,
                        spacing: 20,
                        children: [
                          _DetailTile(title: 'Karyawan', value: e.employeeName),
                          _DetailTile(title: 'Departemen', value: e.department),
                          _DetailTile(
                              title: 'Tanggal',
                              value:
                                  '${_fmtDate(e.startDate)} — ${_fmtDate(e.endDate)}'),
                          _DetailTile(title: 'Durasi', value: '${e.days} hari'),
                          _DetailTile(
                              title: 'Jenis', value: _labelType(e.type)),
                          _DetailTile(
                              title: 'Status', value: _labelStatus(e.status)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Alasan',
                          style: base.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FB),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(e.reason, style: base.bodyLarge),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _GhostButton(
                              label: 'Tolak',
                              icon: Icons.cancel,
                              onPressed: e.status == LeaveStatus.rejected
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _reject(e.id);
                                    }),
                          const SizedBox(width: 12),
                          _PrimaryButton(
                              label: 'Setujui',
                              icon: Icons.check_circle,
                              onPressed: e.status == LeaveStatus.approved
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _approve(e.id);
                                    }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool allSelected;
  final bool someSelected;
  final ValueChanged<bool> onToggleAll;
  final String sortField;
  final bool sortAsc;
  final ValueChanged<String> onSort;
  const _HeaderRow({
    required this.allSelected,
    required this.someSelected,
    required this.onToggleAll,
    required this.sortField,
    required this.sortAsc,
    required this.onSort,
  });
  @override
  Widget build(BuildContext context) {
    TextStyle hd = Theme.of(context)
        .textTheme
        .labelLarge!
        .copyWith(fontWeight: FontWeight.w700, color: Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Checkbox(
              value: allSelected,
              tristate: someSelected && !allSelected,
              onChanged: (v) => onToggleAll(v == true),
            ),
          ),
          _SortBtn(
              label: 'Karyawan',
              field: 'nama',
              sortField: sortField,
              sortAsc: sortAsc,
              onTap: () => onSort('nama'),
              width: 220,
              style: hd),
          _SortBtn(
              label: 'Departemen',
              field: 'dept',
              sortField: sortField,
              sortAsc: sortAsc,
              onTap: () => onSort('dept'),
              width: 160,
              style: hd),
          _SortBtn(
              label: 'Tanggal',
              field: 'tanggal',
              sortField: sortField,
              sortAsc: sortAsc,
              onTap: () => onSort('tanggal'),
              width: 220,
              style: hd),
          _SortBtn(
              label: 'Durasi',
              field: 'durasi',
              sortField: sortField,
              sortAsc: sortAsc,
              onTap: () => onSort('durasi'),
              width: 90,
              style: hd,
              align: TextAlign.center),
          _SortBtn(
              label: 'Jenis',
              field: 'jenis',
              sortField: sortField,
              sortAsc: sortAsc,
              onTap: () => onSort('jenis'),
              width: 140,
              style: hd),
          _SortBtn(
              label: 'Status',
              field: 'status',
              sortField: sortField,
              sortAsc: sortAsc,
              onTap: () => onSort('status'),
              width: 130,
              style: hd),
          const SizedBox(
              width: 120, child: Text('Aksi', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _DataRowCard extends StatefulWidget {
  final LeaveRequest data;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onView;
  const _DataRowCard({
    required this.data,
    required this.selected,
    required this.onSelect,
    required this.onApprove,
    required this.onReject,
    required this.onView,
  });
  @override
  State<_DataRowCard> createState() => _DataRowCardState();
}

class _DataRowCardState extends State<_DataRowCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? 0.07 : 0.03),
              blurRadius: _hover ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE9EDF3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Checkbox(
                  value: widget.selected,
                  onChanged: (v) => widget.onSelect(v == true)),
            ),
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 16,
                      child: Text(
                          e.employeeName.isNotEmpty ? e.employeeName[0] : '?')),
                  const SizedBox(width: 10),
                  Flexible(
                      child: Text(e.employeeName,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            SizedBox(
                width: 160,
                child: Text(e.department,
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
            SizedBox(
                width: 220,
                child:
                    Text('${_fmtDate(e.startDate)} — ${_fmtDate(e.endDate)}')),
            SizedBox(
                width: 90,
                child: Text('${e.days}', textAlign: TextAlign.center)),
            SizedBox(
                width: 140,
                child: Text(_labelType(e.type),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 130, child: _StatusChip(status: e.status)),
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GhostIcon(icon: Icons.visibility, onPressed: widget.onView),
                  const SizedBox(width: 8),
                  _GhostIcon(icon: Icons.cancel, onPressed: widget.onReject),
                  const SizedBox(width: 8),
                  _PrimaryIcon(
                      icon: Icons.check_circle, onPressed: widget.onApprove),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LeaveStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String t;
    switch (status) {
      case LeaveStatus.approved:
        bg = const Color(0xFFE8FFF2);
        fg = const Color(0xFF0F9D58);
        t = 'Disetujui';
        break;
      case LeaveStatus.rejected:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        t = 'Ditolak';
        break;
      default:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57C00);
        t = 'Pending';
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
        child:
            Text(t, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _GhostButton(
      {required this.label, required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _GhostIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _GhostIcon({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _PrimaryIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _PrimaryIcon({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  final List<(String, T)> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  const _Segmented(
      {required this.items, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++)
            _SegItem<T>(
              label: items[i].$1,
              val: items[i].$2,
              selected: value == items[i].$2 ||
                  (value == null && items[i].$2 == null),
              onTap: () => onChanged(items[i].$2),
              first: i == 0,
              last: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _SegItem<T> extends StatelessWidget {
  final String label;
  final T? val;
  final bool selected;
  final VoidCallback onTap;
  final bool first;
  final bool last;
  const _SegItem(
      {required this.label,
      required this.val,
      required this.selected,
      required this.onTap,
      required this.first,
      required this.last});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.horizontal(
          left: first ? const Radius.circular(12) : Radius.zero,
          right: last ? const Radius.circular(12) : Radius.zero),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
              left: first ? const Radius.circular(12) : Radius.zero,
              right: last ? const Radius.circular(12) : Radius.zero),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SortBtn extends StatelessWidget {
  final String label;
  final String field;
  final String sortField;
  final bool sortAsc;
  final VoidCallback onTap;
  final double width;
  final TextStyle style;
  final TextAlign? align;
  const _SortBtn(
      {required this.label,
      required this.field,
      required this.sortField,
      required this.sortAsc,
      required this.onTap,
      required this.width,
      required this.style,
      this.align});
  @override
  Widget build(BuildContext context) {
    final active = field == sortField;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Text(label,
                    style: style.copyWith(
                        color: active ? const Color(0xFF2563EB) : style.color),
                    textAlign: align)),
            if (active)
              Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16, color: const Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  const _Glass({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String title;
  final String value;
  const _DetailTile({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: base.bodySmall?.copyWith(
                  color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: base.titleSmall),
        ],
      ),
    );
  }
}

String _labelType(LeaveType t) {
  switch (t) {
    case LeaveType.tahunan:
      return 'Cuti Tahunan';
    case LeaveType.sakit:
      return 'Cuti Sakit';
    case LeaveType.bersama:
      return 'Cuti Bersama';
    case LeaveType.menikah:
      return 'Cuti Menikah';
    case LeaveType.melahirkan:
      return 'Cuti Melahirkan';
    default:
      return 'Lainnya';
  }
}

String _labelStatus(LeaveStatus s) {
  switch (s) {
    case LeaveStatus.approved:
      return 'Disetujui';
    case LeaveStatus.rejected:
      return 'Ditolak';
    default:
      return 'Pending';
  }
}

String _fmtDate(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];
  return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
}

String _fmtRange(DateTimeRange r) {
  return '${_fmtDate(r.start)} — ${_fmtDate(r.end)}';
}

List<LeaveRequest> _seed() {
  final rnd = Random(7);
  final names = [
    'Aisha Putri',
    'Bima Saputra',
    'Citra Ayu',
    'Dimas Pratama',
    'Eka Lestari',
    'Fajar Rizki',
    'Gita Rahma',
    'Hadi Firmansyah',
    'Intan Pertiwi',
    'Joko Santoso',
    'Kirana Dewi',
    'Lutfi Hakim',
    'Maya Sari',
    'Nadia Zahra',
    'Oka Wirawan',
    'Putra Mahendra',
    'Qori Anjani',
    'Rama Dwi',
    'Salsa Anindya',
    'Tegar Maulana',
    'Uli Puspita',
    'Vino Ardi',
    'Wulan Fitri',
    'Yani Safitri',
    'Zaki Ramadhan'
  ];
  final depts = ['HR', 'Finance', 'Warehouse', 'Marketing', 'IT', 'Sales'];
  final reasons = [
    'Acara keluarga di luar kota',
    'Istirahat karena demam tinggi',
    'Pernikahan kerabat dekat',
    'Ibadah tahunan yang terjadwal',
    'Keperluan administrasi penting',
    'Pemulihan pasca operasi ringan',
    'Liburan yang sudah direncanakan',
    'Menemani anggota keluarga sakit',
  ];
  const types = LeaveType.values;
  List<LeaveRequest> list = [];
  for (int i = 0; i < 36; i++) {
    final name = names[rnd.nextInt(names.length)];
    final dept = depts[rnd.nextInt(depts.length)];
    final t = types[rnd.nextInt(types.length)];
    final start = DateTime.now().subtract(Duration(days: rnd.nextInt(120)));
    final dur = 1 + rnd.nextInt(5);
    final end = start.add(Duration(days: dur));
    final st = [
      LeaveStatus.pending,
      LeaveStatus.approved,
      LeaveStatus.rejected
    ][rnd.nextInt(3)];
    final reason = reasons[rnd.nextInt(reasons.length)];
    list.add(LeaveRequest(
      id: 'LR${i + 1}',
      employeeName: name,
      department: dept,
      startDate: start,
      endDate: end,
      days: dur,
      type: t,
      reason: reason,
      status: st,
    ));
  }
  list.sort((a, b) => b.startDate.compareTo(a.startDate));
  return list;
}
